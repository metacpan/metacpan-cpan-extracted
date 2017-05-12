package Bot::Backbone::Identity;
$Bot::Backbone::Identity::VERSION = '0.161950';
use v5.10;
use Moose;

# ABSTRACT: Describes an account sending or receiving a message


has username => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);


has nickname => (
    is          => 'rw',
    isa         => 'Str',
    predicate   => 'has_nickname',
);


has me  => (
    isa         => 'Bool',
    accessor    => 'is_me',
    required    => 1,
    default     => 0,
);


__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Backbone::Identity - Describes an account sending or receiving a message

=head1 VERSION

version 0.161950

=head1 SYNOPSIS

  my $account = Bot::Backbone::Identity->new(
      username => $username,
      nickname => $nickname,
  );

=head1 DESCRIPTION

Holds username and display name information for a chat account.

=head1 ATTRIBUTES

=head2 username

This is the protocol specific username.

=head2 nickname

This is the display name for the account.

=head2 me

This is a boolean value that should be set to true if this identity identifies the robot itself. 

And, by the way, the accessor for this is named C<is_me>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
