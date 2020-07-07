package Bat::Interpreter::Delegate::LineLogger::Silent;

use utf8;

use Moo;
use Types::Standard qw(ArrayRef);
use namespace::autoclean;

with 'Bat::Interpreter::Role::LineLogger';

our $VERSION = '0.023';    # VERSION

sub log_line {
    my $self = shift();
    return 0;
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Bat::Interpreter::Delegate::LineLogger::Silent

=head1 VERSION

version 0.023

=head1 SYNOPSIS

    use Bat::Interpreter;
    use Bat::Interpreter::Delegate::LineLogger::Silent;

    my $silent_line_logger = Bat::Interpreter::Delegate::LineLogger::Silent->new;

    my $interpreter = Bat::Interpreter->new(linelogger => $silent_line_logger);
    $interpreter->run('my.cmd');

=head1 DESCRIPTION

This line logger just discards every line so nothing get logged or printed on STDOUT

=head1 NAME

Bat::Interpreter::Delegate::LineLogger::Silent - LineLogger that just don't log anything

=head1 METHODS

=head2 log_line

=head1 AUTHOR

Pablo Rodríguez González <pablo.rodriguez.gonzalez@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2020 by Pablo Rodríguez González.

This is free software, licensed under:

  The MIT (X11) License

=cut
