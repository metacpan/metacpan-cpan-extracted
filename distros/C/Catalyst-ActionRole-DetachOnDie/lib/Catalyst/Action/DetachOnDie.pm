package Catalyst::Action::DetachOnDie;
{
  $Catalyst::Action::DetachOnDie::VERSION = '0.001006';
}

use Moose;

# ABSTRACT: If something dies in a chain, stop the chain. DEPRECATED IN FAVOR OF CATALYST 5.90040

extends 'Catalyst::Action';
with 'Catalyst::ActionRole::DetachOnDie';

no Moose;

1;

__END__

=pod

=head1 NAME

Catalyst::Action::DetachOnDie - If something dies in a chain, stop the chain. DEPRECATED IN FAVOR OF CATALYST 5.90040

=head1 VERSION

version 0.001006

=head1 SYNOPSIS

 package MyApp::Controller::Foo;
 use Moose;

 BEGIN { extends 'Catalyst::Controller' }

 __PACKAGE__->config(
    action => {
       '*' => { ActionClass => 'DetachOnDie' },
    },
 );

 ...;

=head1 DESCRIPTION

See L<Catalyst::ActionRole::DetachOnDie> for what this thing really is.

=head1 DEPRECATED

Instead of using this module you should use Catalyst 5.90040 and set
the C<abort_chain_on_error_fix> flag.

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
