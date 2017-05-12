package AnyEvent::Subprocess::Types;
BEGIN {
  $AnyEvent::Subprocess::Types::VERSION = '1.102912';
}
# ABSTRACT: C<MooseX::Types> used internally
use MooseX::Types -declare => [ qw{
    Direction
    JobDelegate
    RunDelegate
    DoneDelegate
    SubprocessCode
    CodeList
    WhenToCallBack
}];

use MooseX::Types::Moose qw(Str ArrayRef CodeRef);

subtype Direction, as Str, where {
    $_ eq 'r' || $_ eq 'w' || $_ eq 'rw'
};

role_type JobDelegate, { role => 'AnyEvent::Subprocess::Job::Delegate' };
role_type RunDelegate, { role => 'AnyEvent::Subprocess::Running::Delegate' };
role_type DoneDelegate, { role => 'AnyEvent::Subprocess::Done::Delegate' };

subtype SubprocessCode, as CodeRef;

coerce SubprocessCode, from Str, via {
    my $cmd = $_;
    return sub { no warnings; exec $cmd or die "Failed to exec '$cmd': $!" };
};

coerce SubprocessCode, from ArrayRef[Str], via {
    my $cmd = $_;
    my $str = join ' ', @$cmd;
    return sub { no warnings; exec @$cmd or die "Failed to exec '$str': $!" };
};

subtype CodeList, as ArrayRef[CodeRef];
coerce CodeList, from CodeRef, via { [$_] };

enum WhenToCallBack, qw/Readable Line/;

1;



=pod

=head1 NAME

AnyEvent::Subprocess::Types - C<MooseX::Types> used internally

=head1 VERSION

version 1.102912

=head1 TYPES

    Direction
    JobDelegate
    RunDelegate
    DoneDelegate
    SubprocessCode
    CodeList
    WhenToCallBack

=head1 AUTHOR

Jonathan Rockway <jrockway@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Jonathan Rockway.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

