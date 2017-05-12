package App::wmiirc::Role::Action;
{
  $App::wmiirc::Role::Action::VERSION = '1.000';
}
# ABSTRACT: A role for plugins which define action handlers
use 5.014;
use Moo::Role;
use App::wmiirc::Util;

# So actions can also have keyboard shortcuts
with 'App::wmiirc::Role::Key';

sub _getstash {
  no strict 'refs';
  return \%{ref(shift) . "::"};
}

sub BUILD {}
after BUILD => sub {
  my($self) = @_;

  for my $subname(grep /^action_/, keys _getstash($self)) {
    my $cv = _getstash($self)->{$subname};
    my $name = $subname =~ s/^action_//r;
    $self->core->{actions}{$name} = sub { $cv->($self, @_) };
  }
};

1;

__END__
=pod

=head1 NAME

App::wmiirc::Role::Action - A role for plugins which define action handlers

=head1 VERSION

version 1.000

=head1 AUTHOR

David Leadbeater <dgl@dgl.cx>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by David Leadbeater.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

