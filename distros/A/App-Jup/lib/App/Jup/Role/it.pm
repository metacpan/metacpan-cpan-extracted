package App::Jup::Role::it;
$App::Jup::Role::it::VERSION = '1.01';
# ABSTRACT: deploys an application

use Moo::Role;

sub deploy {
    die "No Jupfile found" unless -f 'Jupfile';
    system('perl -MApp::Jup::DSL Jupfile');
}

1;

__END__

=pod

=head1 NAME

App::Jup::Role::it - deploys an application

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
