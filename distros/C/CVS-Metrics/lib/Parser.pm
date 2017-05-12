package CVS::Metrics::Parser;

use strict;
use warnings;

our $VERSION = '0.18';

use Parse::RecDescent;

our %cvs_log;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless($self, $class);

    my $grammar = q{
        File: EOL rcs working head branch lock access symbolic keyword total selected Description
                {
                    $CVS::Metrics::Parser::cvs_log{$item[3]} = {
                            'rcs file'              => $item[2],
#                           'working file'          => $item[3],
                            'head'                  => $item[4],
#                           'branch'                => $item[5],
#                           'locks'                 => $item[6],
#                           'access list'           => $item[7],
                            'symbolic names'        => $item[8],
#                           'keyword subtitution'   => $item[9],
                            'total revisions'       => $item[10],
#                           'selected revisions'    => $item[11],
                            'description'           => $item[12]
                    };
                }

        rcs: 'RCS file:' /[^,]+/ ',v' EOL
                { $item[2]; }

        working: 'Working file:' /(.*)/ EOL
                { $item[2]; }

        head: 'head:' /(.*)/ EOL
                { $item[2]; }

        branch: 'branch:' /(.*)/ EOL
                { $item[2]; }

        lock: 'locks:' /(.*)/ EOL
                { $item[2]; }

        access: 'access list:' /(.*)/ EOL
                { $item[2]; }

        symbolic: 'symbolic names:' EOL Tag(s?)
                {
                    my @list;
                    foreach (@{$item[3]}) {
                        push @list, @{$_};
                    }
                    my %hash = @list;
                    \%hash;
                }

        Tag: /[0-9A-Za-z_\-\.]+/ ':' /[0-9\.]+/ EOL
                {
                    [ $item[1], $item[3] ];
                }

        keyword: 'keyword substitution:' /(.*)/ EOL
                { $item[2]; }

        total: 'total revisions:' /[0-9]+/ SEMICOL
                { $item[2]; }

        selected: 'selected revisions:'  /[0-9]+/ EOL
                { $item[2]; }

        Description: 'description:' EOL imported(?) Revision(s)
                {
                    my @list;
                    foreach (@{$item[4]}) {
                        push @list, @{$_};
                    }
                    my %hash = @list;
                    \%hash;
                }

        imported: /(Imported|\.)/ /(.*)/ EOL

        Revision: /[-]+\n/ id date author state line(?) EOL branches(?) EOL(s?) message(s?)
                {
                    [
                        $item[2],
                        {
                                'date'      => $item[3],
                                'author'    => $item[4],
                                'state'     => $item[5],
#                               'line_add'  => ${$item[6]}[0],
#                               'line_del'  => ${$item[6]}[1],
                                'branches'  => ${$item[8]}[0],
                                'message'   => join "\n", @{$item[10]},
                        }
                    ];
                }

        id: 'revision' /[0-9\.]+/ EOL
                { $item[2]; }

        date: 'date:' /[^;]+/ SEMICOL
                { $item[2]; }

        author: 'author:' /[^;]+/ SEMICOL
                { $item[2]; }

        state: 'state:' /[^;]+/ SEMICOL
                { $item[2]; }

        line: 'lines:' /[-+]?[0-9]+/ /[-+]?[0-9]+/
                { [ $item[2] , $item[3] ]; }

        branches: 'branches:' Rev(s) EOL
                { $item[2]; }

        Rev: /[0-9\.]+/ SEMICOL
                { $item[1]; }

        message: /([^\-].*)|([-]+[^\-\n].*)/ EOL
                { $item[1] || $item[2]; }

        SEMICOL: ';'

        EOL: /\n/
    };
    $Parse::RecDescent::skip = '[ \t]*';
    $self->{parser} = Parse::RecDescent->new($grammar);
    return undef unless (defined $self->{parser});
    return $self;
}

sub parse {
    my $self = shift;
    my ($cvs_logfile) = @_;

    %cvs_log = ();
    $Parse::RecDescent::skip = '[ \t]*';
#   $::RD_TRACE = 1;
    my $text;
    open my $IN, $cvs_logfile
            or die "can't open CVS output ($!).\n";
    while (<$IN>) {
        $text = $_;
        last unless (/^\?/);
    }
    while (<$IN>) {
        if (/^[=]+$/) {
            unless (defined $self->{parser}->File($text)) {
                warn "Not matched\n$text\n";
            }
            $text = '';
        }
        else {
            $text .= $_;
        }
    }
    close $IN;
    my $metric = \%cvs_log;
    return bless $metric, 'CVS::Metrics';
}

1;

