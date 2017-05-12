package Data::Localize::Log;
use strict;
use base qw(Exporter);
use Log::Minimal ();
our @EXPORT;
our $PRINT;
BEGIN {
    @EXPORT = @Log::Minimal::EXPORT;
    $PRINT = sub {
        printf STDERR "%5s [%s] %s\n",
            $$,
            $_[1],
            $_[2],
    };
    $Log::Minimal::ENV_DEBUG = 'DATA_LOCALIZE_DEBUG';
    foreach my $sub (@EXPORT) {
        no strict 'refs';
        *{$sub} = sub {
            local $Log::Minimal::PRINT = $PRINT;
            (\&{"Log::Minimal::$sub"})->(@_);
        }
    }
}

1;

__END__

=head1 NAME

Data::Localze::Log - Internal Logging Facilities

=head1 SYNOPSIS

Private use only. Provides all of the Log::Minimal functions

=head1 FUNCTIONS

=head2 critf
=head2 critff
=head2 croakf
=head2 croakff
=head2 ddf
=head2 debugf
=head2 debugff
=head2 infof
=head2 infoff
=head2 warnf
=head2 warnff

=cut
