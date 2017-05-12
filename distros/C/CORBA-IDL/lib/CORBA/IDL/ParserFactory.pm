
#
#           Interface Definition Language (OMG IDL CORBA v3.0)
#

package CORBA::IDL::ParserFactory;

use strict;
use warnings;

our $VERSION = '2.60';

use CORBA::IDL::Lexer;
use CORBA::IDL::Symbtab;
use CORBA::IDL::Node;

sub create {
    my ($version) = @_;

    $version = '30' unless (defined $version);
    $version =~ s/\.//g;
    eval "require CORBA::IDL::Parser$version";
    die $@ if ($@);
    my $parser = new CORBA::IDL::Parser();
    $parser->YYData->{verbose_error} = 1;       # 0, 1
    $parser->YYData->{verbose_warning} = 1;     # 0, 1
    $parser->YYData->{verbose_info} = 1;        # 0, 1
    $parser->YYData->{verbose_deprecated} = 0;  # 0, 1 (concerns only version '2.4' and upper)
    $parser->YYData->{collision_allowed} = 0;   # 0, 1
    $parser->YYData->{symbtab} = new CORBA::IDL::Symbtab($parser);
    return $parser;
}

package CORBA::IDL::Parser;

use strict;
use warnings;

sub getopts {           # from Getopt::Std
    no strict;
    my $parser = shift;
    local($argumentative) = @_;
    local(@args, $_, $first, $rest);

    $parser->YYData->{args} = [];
    @args = split( / */, $argumentative );
    while (@ARGV && ($_ = $ARGV[0]) =~ /^-(.)(.*)/) {
        ($first, $rest) = ($1, $2);
        if (/^--$/) {   # early exit if --
            shift(@ARGV);
            last;
        }
        $pos = index($argumentative,$first);
        if ($pos >= 0) {
            if (defined($args[$pos+1]) and ($args[$pos+1] eq ':')) {
                shift(@ARGV);
                if ($rest eq q{}) {
                    $rest = shift(@ARGV);
                }
                $parser->YYData->{"opt_$first"} = $rest;
            }
            else {
                $parser->YYData->{"opt_$first"} = 1;
                if ($rest eq q{}) {
                    shift(@ARGV);
                }
                else {
                    $ARGV[0] = "-$rest";
                }
            }
        }
        else {
            push @{$parser->YYData->{args}}, shift(@ARGV);
        }
    }
}

sub Configure {
    my $parser = shift;
    my %attr = @_;
    while ( my ($key, $value) = each(%attr) ) {
        if (defined $value) {
            $parser->YYData->{$key} = $value;
        }
    }
    return $parser;
}

sub Run {
    my $parser = shift;
    my $preprocessor = $parser->YYData->{preprocessor};

    if ($preprocessor) {
        my @args;
        @args = @{$parser->YYData->{args}}
                if (exists $parser->YYData->{args});
        push @args, @_;

        open $parser->YYData->{fh}, "$preprocessor @args|"
                or die "can't open @_ ($!).\n";
    }
    else {
        my $file = shift;
        if (ref $file) {
            $parser->YYData->{fh} = $file;
            $parser->YYData->{srcname} = shift;
        }
        else {
            open $parser->YYData->{fh}, $file
                    or die "can't open $file ($!).\n";
            $parser->YYData->{srcname} = shift || $file;
        }
        my @st = stat($parser->YYData->{srcname});
        $parser->YYData->{srcname_size} = $st[7];
        $parser->YYData->{srcname_mtime} = $st[9];
    }

    CORBA::IDL::Lexer::InitLexico($parser);
    $parser->YYData->{doc} = q{};
    $parser->YYData->{curr_node} = undef;
    $parser->YYData->{curr_itf} = undef;
    $parser->YYData->{prop} = 0;
    $parser->YYData->{native} = 0;
    $parser->YYParse(
            yylex   => \&CORBA::IDL::Lexer::Lexer,
            yyerror => sub { return; },
#           yydebug => 0x17,
    );

#    Bit Value    Outputs
#    0x01         Token reading (useful for Lexer debugging)
#    0x02         States information
#    0x04         Driver actions (shifts, reduces, accept...)
#    0x08         Parse Stack dump
#    0x10         Error Recovery tracing

    close $parser->YYData->{fh};
    delete $parser->{RULES};
    delete $parser->{STATES};
    delete $parser->{STACK};

    if (exists $parser->YYData->{symbtab}) {
        $parser->YYData->{symbtab}->CheckForward();
        $parser->YYData->{symbtab}->CheckRepositoryID();
    }
}

sub DisplayStatus {
    my $parser = shift;
    if (exists $parser->YYData->{nb_error}) {
        my $nb = $parser->YYData->{nb_error};
        print "$nb error(s).\n"
    }
    if (        $parser->YYData->{verbose_warning}
            and exists $parser->YYData->{nb_warning} ) {
        my $nb = $parser->YYData->{nb_warning};
        print "$nb warning(s).\n"
    }
    if (        $parser->YYData->{verbose_info}
            and exists $parser->YYData->{nb_info} ) {
        my $nb = $parser->YYData->{nb_info};
        print "$nb info(s).\n"
    }
    if (        $parser->YYData->{verbose_deprecated}
            and exists $parser->YYData->{nb_deprecated} ) {
        my $nb = $parser->YYData->{nb_deprecated};
        print "$nb deprecated(s).\n"
    }
}

sub Export {
    my $parser = shift;
    if ( our $IDL_VERSION ge '3.0' ) {
        $parser->YYData->{symbtab}->Export();
    }
}

sub getRoot {
    my $parser = shift;
    if (        exists $parser->YYData->{root}
            and ! exists $parser->YYData->{nb_error} ) {
        return $parser->YYData->{root};
    }
    return undef;
}

sub Error {
    my $parser = shift;
    my ($msg) = @_;

    $msg ||= "Syntax error.\n";

    if (exists $parser->YYData->{nb_error}) {
        $parser->YYData->{nb_error} ++;
    }
    else {
        $parser->YYData->{nb_error} = 1;
    }

    unless (exists $parser->YYData->{filename}) {
        print STDOUT "#No parsed input : ",$msg;
    }
    else {
        print STDOUT '#',$parser->YYData->{filename},':',$parser->YYData->{lineno},'#Error: ',$msg
                if (        exists $parser->YYData->{verbose_error}
                        and $parser->YYData->{verbose_error});
    }
}

sub Warning {
    my $parser = shift;
    my ($msg) = @_;

    $msg ||= ".\n";

    if (exists $parser->YYData->{nb_warning}) {
        $parser->YYData->{nb_warning} ++;
    }
    else {
        $parser->YYData->{nb_warning} = 1;
    }

    print STDOUT '#',$parser->YYData->{filename},':',$parser->YYData->{lineno},'#Warning: ',$msg
            if (        exists $parser->YYData->{verbose_warning}
                    and $parser->YYData->{verbose_warning});
}

sub Info {
    my $parser = shift;
    my ($msg) = @_;

    $msg ||= ".\n";

    if (exists $parser->YYData->{nb_info}) {
        $parser->YYData->{nb_info} ++;
    }
    else {
        $parser->YYData->{nb_info} = 1;
    }

    print STDOUT '#',$parser->YYData->{filename},':',$parser->YYData->{lineno},'#Info: ',$msg
            if (        exists $parser->YYData->{verbose_info}
                    and $parser->YYData->{verbose_info});
}

sub Deprecated {
    my $parser = shift;
    my ($msg) = @_;

    $msg ||= ".\n";

    if (exists $parser->YYData->{nb_deprecated}) {
        $parser->YYData->{nb_deprecated} ++;
    }
    else {
        $parser->YYData->{nb_deprecated} = 1;
    }

    print STDOUT '#',$parser->YYData->{filename},':',$parser->YYData->{lineno},'#Deprecated: ',$msg
            if (        exists $parser->YYData->{verbose_deprecated}
                    and $parser->YYData->{verbose_deprecated});
}

1;

