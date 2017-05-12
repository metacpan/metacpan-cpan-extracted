#Copyright barry king <barry@wyrdwright.com> and released under the GPL.
#See http://www.gnu.org/licenses/gpl.html#TOC1 for details
use 5.006;
use strict;
use warnings;
no warnings qw(uninitialized);

package Apache::Wyrd::Services::Tree;
our $VERSION = '0.98';

=head1 NAME

Apache::Wyrd::Services::Tree - Data-tree storage object

=head1 DESCRIPTION

Very simple object for storing values of any sort with no checking.

=head1 SYNOPSIS

    my $tree=Apache::Wyrd::Services::Tree->new(
      {key1 => value1, key2 => value2, key3 => [a, b, c]}
    );

    my $tree=Apache::Wyrd::Services::Tree->new(
      {key1 => value1, key2 => value2, _debug => 1}
    );

    print $tree->key1; #prints value1

    $tree->key1('value4')

    print $tree->key1; #prints value4

=head1 METHODS

Tree uses an initialization hash for the initial state.  Tree items are added to/set
by calling the tree-node name.  When an argument is supplied, it is assigned to the
key.

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

sub new {
	my ($class, $init) = @_;
	my $data = ($init || {});
	bless $data, $class;
	return $data;
}

sub AUTOLOAD {
	no strict 'vars';
	my ($self, $newval) = @_;
	return undef if $AUTOLOAD =~ /DESTROY$/;
	$AUTOLOAD =~ s/.*:://;
	if(defined($self->{$AUTOLOAD})){
		return $self->{$AUTOLOAD} unless (scalar(@_) == 2);
		$self->{$AUTOLOAD} = $newval;
		return $newval;
	} else {
		$self->{$AUTOLOAD} = $newval;
		return;
	}
}

1;
