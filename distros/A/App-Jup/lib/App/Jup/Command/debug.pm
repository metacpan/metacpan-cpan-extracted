package App::Jup::Command::debug;
$App::Jup::Command::debug::VERSION = '1.01';
# ABSTRACT: Runs jup debugger

use App::Jup -command;

use Moo;
use namespace::clean;


sub abstract {'Run jup debugger'}

sub usage_desc { '%c %o' }

sub validate_args {
    my ($self, $opt, $args) = @_;
    $self->usage_error('jup debug') unless $opt->{debug};
}

sub execute {
    my ($self, $opt, $arg) = @_;
    print("Debugging Jupfile deployment.\n");
}

1;

__END__

=pod

=head1 NAME

App::Jup::Command::debug - Runs jup debugger

=head1 SYNOPSIS

Runs jup debugger

    # Your cwd should have a Jupfile
    $ cd Projects/nginx/
    # Run jup as normal but with debug argument
    $ jup debug

=head1 AUTHOR

Adam Stokes <adamjs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Adam Stokes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
