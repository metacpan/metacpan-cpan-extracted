
package Clio::Log::Log4perl;
BEGIN {
  $Clio::Log::Log4perl::AUTHORITY = 'cpan:AJGB';
}
{
  $Clio::Log::Log4perl::VERSION = '0.02';
}
# ABSTRACT: Log4perl log implementation

use strict;
use Moo;
use Log::Log4perl qw( get_logger );

extends qw( Clio::Log );



sub init {
    my $self = shift;

    my $config = $self->c->config->LogConfig;

    if ( my $ro_config = $config->{Config} ) {
        my $config_text = join("\n",
            map { "$_ = $ro_config->{$_}" } keys %$ro_config
        );

        Log::Log4perl::init( \$config_text ); 
    }
}


sub logger {
    my $self = shift;

    return get_logger(@_);
}


1;


__END__
=pod

=encoding utf-8

=head1 NAME

Clio::Log::Log4perl - Log4perl log implementation

=head1 VERSION

version 0.02

=head1 DESCRIPTION

Implement L<Log::Log4perl> as logging class.

=head1 METHODS

=head2 init

Called during start of application, initializes the logger with
E<lt>LogE<gt>/E<lt>Config<gt> text.

=head2 logger

Returns the logger.

=head1 AUTHOR

Alex J. G. Burzyński <ajgb@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Alex J. G. Burzyński <ajgb@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

