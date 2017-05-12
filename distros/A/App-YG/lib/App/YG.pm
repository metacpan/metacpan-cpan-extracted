package App::YG;
use strict;
use warnings;
use Carp qw/croak/;
use Getopt::Long qw/GetOptionsFromArray/;
use Pod::Usage;
use IO::Interactive qw/is_interactive/;
use Term::ANSIColor qw/colored/;

our $VERSION = '0.063';

our $CONFIG_FILE    = '.ygconfig';
our $DEFAULT_PARSER = 'apache-combined';
our $DIGEST_LENGTH = 6;
our $DEFAULT_COLOR = +{
    label  => 'blue',
    colon  => 'cyan',
    value  => 'green',
    hr     => 'yellow',
    count  => 'red',
    digest => 'magenta',
};

use Class::Accessor::Lite (
    new => 1,
    rw  => [qw/
        config
        parse_class
        parse_func
        labels
        label_format
        count
        hr
    /],
);

sub run {
    my $self = shift;
    $self->pre(\@_)->loop;
}

sub loop {
    my $self = shift;

    $self->count(1);
    if ( !is_interactive() ) {
        while ( my $line = <STDIN> ) {
            $self->_out_put(\$line);
        }
    }
    elsif ( scalar @{ $self->config->{file} } ) {
        for my $file (@{$self->config->{file}}) {
            open my $fh, '<', $file or croak $!;
            while ( my $line = <$fh> ) {
                $self->_out_put(\$line);
            }
            close $fh;
        }
    }

    return 1;
}

sub _out_put {
    my ($self, $line_ref) = @_;

    chomp ${$line_ref};

    if ( ( !$self->config->{match} && !$self->config->{regexp} )
            || ( $self->config->{match} && $self->_match($line_ref) )
                || ( $self->config->{regexp} && $self->_regexp($line_ref) )
    ) {
        $self->__out($line_ref);
    }
    else {
        return;
    }
}

sub __out {
    my ($self, $line_ref) = @_;

    if ($self->config->{through}) {
        print "${$line_ref}\n";
        return;
    }

    if (!$self->config->{nohr}) {
        my $digest = '';
        if ($self->config->{digest}) {
            $digest = substr(Digest::SHA1::sha1_hex(${$line_ref}), 0, $DIGEST_LENGTH);
        }
        $self->_output_head($self->count, $digest);
    }

    $self->_output_raw($line_ref) if $self->config->{raw};

    if ($self->config->{ltsv}) {
        $self->_output_ltsv_line($line_ref);
    }
    elsif ( $self->config->{tab} || $self->config->{space} ) {
        $self->_output_splited_line($line_ref);
    }
    else {
        $self->_output_parsed_line($line_ref);
    }

    $self->count( $self->count() + 1 );
    return;
}

sub _match {
    my ($self, $line_ref) = @_;

    return 1 if index(${$line_ref}, $self->{config}->{match}) > -1;
}

sub _regexp {
    my ($self, $line_ref) = @_;

    if ($self->config->{ignore_case}) {
        return 1 if ${$line_ref} =~ m!$self->{config}->{regexp}!i;
    }
    else {
        return 1 if ${$line_ref} =~ m!$self->{config}->{regexp}!;
    }
}

sub _output_head {
    my ($self, $count, $digest) = @_;

    my $colon = $digest ? ': ' : '';

    if ($self->config->{color}) {
        print colored($self->hr.' ', $self->config->{_color}{hr});
        print colored($count, $self->config->{_color}{count});
        print colored($colon, $self->config->{_color}{colon});
        print colored($digest, $self->config->{_color}{digest});
        print colored(' '.$self->hr, $self->config->{_color}{hr});
        print "\n";
    }
    else {
        print $self->hr. " $count$colon$digest ". $self->hr. "\n";
    }
}

sub _output_raw {
    print "${$_[1]}\n";
}

sub _output_ltsv_line {
    my ($self, $line_ref) = @_;

    my $delimiter = "\t";

    my @cols = split $delimiter, ${$line_ref};
    my @labels;
    for my $col (@cols) {
        my ($label, $value) = split ':', $col;
        push @labels, $label;
    }
    my $lablel_width = _max_label_len(\@labels);

    for my $col (@cols) {
        my ($label, $value) = split ':', $col;
        $self->__output_line( sprintf("%${lablel_width}s", $label), $value );
    }
    print "\n";
}

sub _output_parsed_line {
    my ($self, $line_ref) = @_;

    my $logs;
    {
        no strict 'refs'; ## no critic
        $logs = &{ $self->parse_func }(${$line_ref});
    }
    if (@{$logs}) {
        my $i = 0;
        for my $label (@{$self->labels}) {
            $self->__output_line( sprintf($self->label_format, $label), $logs->[$i] );
            $i++;
        }
    }
    else {
        print ${$line_ref};
    }
    print "\n";
}

sub _output_splited_line {
    my ($self, $line_ref) = @_;

    my $delimiter = $self->config->{space} ? ' ' : "\t";
    my $i = 1;
    my @cols = split $delimiter, ${$line_ref};

    if ($self->config->{number}) {
        my $j = length(scalar @cols);
        for my $col (@cols) {
            $self->__output_line( sprintf("%${j}d", $i), $col );
            $i++;
        }
    }
    else {
        for my $col (@cols) {
            $self->__output_line( '', $col );
            $i++;
        }
    }
    print "\n";
}

sub __output_line {
    my ($self, $label, $value) = @_;

    if ($self->config->{color}) {
        print colored($label, $self->config->{_color}{label});
        print colored(': ', $self->config->{_color}{colon}) if $label;
        print colored("$value\n", $self->config->{_color}{value});
    }
    else {
        print "$label: " if $label;
        print "$value\n";
    }
}

sub pre {
    my ($self, $argv) = @_;

    my $config = $self->_set_config;
    $self->_merge_opt($config, $argv);
    $self->config($config);
    $self->parse_class(
        $self->_load_parser($config->{parser} || $DEFAULT_PARSER)
    );
    $self->parse_func( $self->parse_class. '::parse');
    {
        no strict 'refs'; ## no critic
        $self->labels( &{ $self->parse_class. '::labels' }() );
    }
    $self->label_format(
        '%'. _max_label_len($self->labels). 's'
    );

    if ($self->config->{digest}) {
        eval { require Digest::SHA1; };
        croak $@ if $@;
    }

    if ($self->config->{color}) {
        for my $k (keys %{$DEFAULT_COLOR}) {
            $self->config->{_color}{$k}
                = $self->config->{"color-$k"} || $DEFAULT_COLOR->{$k};
        }
    }

    $self->hr($self->_hr);

    $self;
}

sub _hr {
    my $self = shift;

    my $hr     = $self->config->{hr}         || '*';
    my $hr_num = $self->config->{'hr-count'} || 20;
    return scalar($hr x $hr_num);
}

sub _set_config {
    my $self = shift;

    my %config;
    for my $dir ($ENV{YG_DIR}, $ENV{HOME}) {
        next unless $dir;
        next unless -e "$dir/$CONFIG_FILE";
        $self->__read_config("$dir/$CONFIG_FILE" => \%config);
    }

    return \%config;
}

sub __read_config {
    my ($self, $file, $config) = @_;

    open my $fh, '<', $file or croak $!;
    while (<$fh>) {
        chomp;
        next if /\A\s*\Z/sm;
        if (/\A(\w+):\s*(.+)\Z/sm) {
            my ($key, $value) = ($1, $2);
            if ($key eq 'file') {
                push @{$config->{$key}}, $value;
            }
            else {
                $config->{$key} = $value;
            }
        }
    }
    close $fh;
}

sub _merge_opt {
    my ($self, $config, $argv) = @_;

    Getopt::Long::Configure('bundling');
    GetOptionsFromArray(
        $argv,
        'f|file=s@'      => \$config->{file},
        'p|parser=s'     => \$config->{parser},
        'tab'            => \$config->{tab},
        'space'          => \$config->{space},
        'n|number!'      => \$config->{number},
        'm|match=s'      => \$config->{match},
        're|regexp=s'    => \$config->{regexp},
        'i|ignore-case!' => \$config->{ignore_case},
        'r|raw'          => \$config->{raw},
        't|through'      => \$config->{through},
        'digest!'        => \$config->{digest},
        'ltsv'           => \$config->{ltsv},
        'c|color!'       => \$config->{color},
        'color-label=s'  => \$config->{color_label},
        'color-colon=s'  => \$config->{color_colon},
        'color-value=s'  => \$config->{color_value},
        'color-hr=s'     => \$config->{color_hr},
        'color-count=s'  => \$config->{color_count},
        'color-digest=s' => \$config->{color_digest},
        'hr=s'           => \$config->{hr},
        'hr-count=i'     => \$config->{'hr-count'},
        'nohr'           => \$config->{'nohr'},
        'h|help'         => sub {
            pod2usage(1);
        },
        'v|version'     => sub {
            print "yg v$App::YG::VERSION\n";
            exit 1;
        },
    ) or pod2usage(2);

    push @{$config->{file}}, @{$argv};
}

sub _load_parser {
    my ($self, $parser) = @_;

    my $class = __PACKAGE__. join('', map { '::'.ucfirst($_) } split('-', $parser));
    my $file = $class;
    $file =~ s!::!/!g;
    eval {
        require "$file.pm"; ## no critic
    };
    if ($@) {
        croak "wrong parser: $parser, $@";
    }
    return $class;
}

sub _max_label_len {
    my $labels = shift;

    my $max = 0;
    for my $label (@{$labels}) {
        my $len = length($label);
        $max = $len if $max < $len;
    }
    return $max;
}

1;

__END__

=head1 NAME

App::YG - log line filter, like \G of MySQL


=head1 SYNOPSIS

    use App::YG;

    my $yg = App::YG->new;
    $yg->run(@ARGV);

See command L<yg>.


=head1 METHOD

=over

=item new

constructor

=item run(I<@ARGV>)

execute command

=item pre

prepare for showing logs

=item loop

loop for showing logs

=back


=head1 SEE ALSO

L<yg>


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
