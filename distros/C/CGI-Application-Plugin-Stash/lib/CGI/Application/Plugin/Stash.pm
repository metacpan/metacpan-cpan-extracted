package CGI::Application::Plugin::Stash;

use strict;
use warnings;
use vars qw($VERSION @EXPORT);
require Exporter;

@EXPORT = qw(stash);
$VERSION = '0.01';

sub import { goto &Exporter::import }

sub stash{
    my $self = shift;
    
    # First use?  Create new __PARAMS!
    $self->{__PARAMS} = {} unless (exists($self->{__PARAMS}));
    
    # This code stolen from Catalyst::Engine
    if (@_) {
        my $stash = @_ > 1 ? {@_} : $_[0];
        while ( my ( $key, $val ) = each %$stash ) {
            $self->{__PARAMS}->{$key} = $val;
        }
    }
    
    return $self->{__PARAMS};
}

1;


__END__

=head1 NAME

CGI::Application::Plugin::Stash - add stash to CGI::Application

=head1 SYNOPSIS

  use CGI::Application::Plugin::Stash;
  
  $self->stash->{foo}='bar';
  
  $self->param('foo','bar'); #same
  

=head1 DESCRIPTION

CGI::Application::Plugin::Stash is a plugin for CGI::Application. This module allow you to call stash like L<Catalyst>.


=head1 SEE ALSO

L<CGI::Application>

L<Catalyst>

=head1 AUTHOR

Masahiro Nagano, E<lt>kazeburo@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 by Masahiro Nagano

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
