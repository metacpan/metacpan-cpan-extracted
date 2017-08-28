package BioSAILs::Utils::CacheUtils;

use Moose::Role;
use namespace::autoclean;

with 'BioSAILs::Utils::LoadConfigs';

use YAML;

=head3 comment_char

Default comment char is '#'.

=cut

has 'comment_char' => (
    is      => 'rw',
    isa     => 'Str',
    default => '#',
);

sub print_cmd_line_opts {
    my $self = shift;

    my $now           = DateTime->now();
    my $cmd_line_opts = "";

    $cmd_line_opts .= "$self->{comment_char}\n";
    $cmd_line_opts .= "$self->{comment_char} Generated at: $now\n";
    $cmd_line_opts .=
        "$self->{comment_char} "
      . "This file was generated with the following options\n";

    $cmd_line_opts .= "$self->{comment_char}\t" . $ARGV[0] . "\n" if $ARGV[0];
    for ( my $x = 1 ; $x <= $#ARGV ; $x++ ) {
        next unless $ARGV[$x];
        $cmd_line_opts .= "$self->{comment_char}\t$ARGV[$x]";
        if ( $x == $#ARGV ) {
            $cmd_line_opts .= "\n";
        }
        else {
            $cmd_line_opts .= "\t\\\n";
        }
    }

    $cmd_line_opts .= "$self->{comment_char}\n\n";

    return $cmd_line_opts;
}

sub print_config_data {
    my $self = shift;

    return "" unless scalar keys %{ $self->_merged_config_data };
    my $config_str  = Dump( $self->_merged_config_data );
    my @split       = split( "\n", $config_str );
    my $config_opts = "";

    $config_opts .= "$self->{comment_char}\n";
    $config_opts .= "$self->{comment_char} " . "Invoked with configuration:\n";

    map { $config_opts .= "# " . $_ ."\n" } @split;

    $config_opts .= "\n";

    return $config_opts;
}

1;
