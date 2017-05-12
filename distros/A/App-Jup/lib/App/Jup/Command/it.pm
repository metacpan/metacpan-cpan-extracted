package App::Jup::Command::it;
$App::Jup::Command::it::VERSION = '1.01';
# ABSTRACT: Runs jup deployment

use App::Jup -command;
use Moo;
with('App::Jup::Role::it');
use namespace::clean;


sub abstract {'Run jup it'}

sub usage_desc { '%c %o' }

sub execute {
    my ($self, $opt, $arg) = @_;
    print("Deploying your environment.\n");
    $self->deploy;
}

1;

__END__

=pod

=head1 NAME

App::Jup::Command::it - Runs jup deployment

=head1 SYNOPSIS

Runs jup

    # Your cwd should have a Jupfile
    $ cd MyApplication
    $ jup it

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
