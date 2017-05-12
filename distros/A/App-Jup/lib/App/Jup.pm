package App::Jup;
$App::Jup::VERSION = '1.01';
use Modern::Perl;
use App::Cmd::Setup -app;

# ABSTRACT: Global Jup options

sub global_opt_spec {
    return (["verbose|v:s@", "extra logging"]);
}

1;

__END__

=pod

=head1 NAME

App::Jup - Global Jup options

=head1 DESCRIPTION

Processes a Jupfile for performing build and deployment tasks of your
application in a Juju enabled environment.

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
