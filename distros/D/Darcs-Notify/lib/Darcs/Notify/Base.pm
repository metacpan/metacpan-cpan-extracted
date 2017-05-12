#  Copyright (c) 2009 David Caldwell,  All Rights Reserved.

package Darcs::Notify::Base; use strict; use warnings;

sub new($%) {
    my ($class, %options) = @_;
    bless { %options }, $class;
}

sub notify($$$$) {
    my ($self, $notify, $add, $unpull) = @_;
    eval "use Data::Dumper;"; # don't load this unless you are using the defaults for some reason.
    print Data::Dumper->Dump([$self, $add, $unpull], [qw"self add unpull"]);
}

1;
__END__

=head1 NAME

Darcs::Notify::Base - Base class for notifiers

=head1 SYNOPSIS

 package Darcs::Notify::MySubclass;
 use Darcs::Notify::Base;
 use base 'Darcs::Notify::Base';

 sub notify($$$$) {
     my ($self, $notify, $new, $unpull) = @_;
     print $self->{option1}, "\n";
     print $notify->repo_name, "\n";
     print "Added patches:\n";
     print "$_" for (@{$new});
     print "Unpulled patches:\n";
     print "$_" for (@{$unpull});
 }

 use Darcs::Notify;
 Darcs::Notify->new(MySubclass => { option1 => 1,
                                    option2 => 2 })
     ->notify;

=head1 DESCRIPTION

This is the base class for making custom L<Darcs::Notify>
notifiers. Subclass this and make sure that your package name is in
the Darcs::Notify hierarchy. Pass the last part of your package name
to B<< L<Darcs::Notify>->new() >> to have it use your package. If your package is called
B<Darcs::Notify::Something> then you would pass something like S<< B<< C<<
Something => { my_option1 => 1, my_option2 => 2 } >> >> >>.  B<<
L<Darcs::Notify>->new() >> will load your subclass if it is not
already loaded and call its B<new()> function with the option hash
that was passed to it.

=head1 FUNCTIONS

=over 4

=item B<new(%options)>

This instantiates your object. Generally you won't I<need> to override
this class, but you may I<want> to in order to check that the options
are valid, for instance.

The B<< Darcs::Notify::Base->new() >> will put all the options passed
to it into the B<$self> blessed hash, but there is no requirement that
your class has to work this way.

=item B<< $self->notify($notify, [@new_patches], [@unpulled_patches]) >>

This does the actual notifying. The subroutine defined in
this module is just a stub and only prints some debugging
information. Normally your subclass overrides this to do whatever
notifications you'd like. See L<Darcs::Notify::Email> which is the
only subclass that comes with Darcs::Notify at the moment.

The first parameter passed is the $self hash ref. If you don't
override the B<new()> function, any options you pass to B<new()> will
end up in the $self hash ref.

The second parameter is a reference to the L<Darcs::Notify>
object. You can use this to query the repo_name, for instance.

The third parameter is a reference to an array of
L<Darcs::Inventory::Patch>es that are new in the repository.

The fourth parameter is a reference to an array of
L<Darcs::Inventory::Patch>es that have been unpulled (obliterated)
from the repository.

=back

=head1 SEE ALSO

L<darcs-notify>, L<Darcs::Notify::Base>, L<Darcs::Notify::Email>,
L<Darcs::Inventory::Patch>

I also recommend looking at the source code for
L<Darcs::Notify::Email> as it is a subclass of Darcs::Notify::Base.

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

Copyright (C) 2007-2009 David Caldwell

=head1 AUTHOR

David Caldwell <david@porkrind.org>

=cut
