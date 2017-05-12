package Class::DBI::TempEssential;

use 5.006;
use strict;
use warnings;
use Carp;

our $VERSION = do { my @r = (q$Revision: 0.4 $ =~ /\d+/g); sprintf " %d." . "%02d" x $#r, @r };

sub new {
    my ($class, $cdbi, @more) = @_;
    $class = ref($class) || $class;
    $cdbi = ref($cdbi) || $cdbi;
    unless ($cdbi->isa('Class::DBI')) {
	carp ("$cdbi is not a Class::DBI");
	return;
    }
    my $self = {
		_ALL => [$cdbi->columns],
		_CDBI => $cdbi,
		_ORIG_ESSENTIAL => [$cdbi->_essential],
	       };
    bless $self, $class;
    if (ref($more[0]) eq 'ARRAY') {
	$self->set_essential(@{$more[0]});
    } else {
	$self->set_essential(@more);
    }
    return $self;
}

sub set_essential {
    my ($self, @essentials) = @_;
    my $cdbi = $self->{_CDBI};
    my @old_essentials = $cdbi->columns('Essential');
    $cdbi->columns(Essential =>  @essentials);
    $cdbi->columns(All => @{ $self->{_ALL} });
    return @old_essentials;
}

sub reset_essential {
    return $_[0]->set_essential(@{ $_[0]->{_ORIG_ESSENTIAL} });
}

sub DESTROY {
    eval {
	# might fail when cdbi already destroyed
	local $^W = 0;
	$_[0]->reset_essential;
    };
}



1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Class::DBI::TempEssential - CDBI extension for temporary essentials

=head1 SYNOPSIS

  use Class::DBI::TempEssential;

  # $cdbi_table ISA Class::DBI table
  my @new_essential = qw/col1 col5 col7/;
  my $tempEssential = new Class::DBI::TempEssential($cdbi_table,
						    @new_essential);

  # do what you want to do with this essential setting

  undef $tempEssential; # or get out of my-scope
  # you have your old setting back

=head1 DESCRIPTION

TempEssential modifies the Essential columns of a Class::DBI table. It
reverts the original Essential columns when getting out of scope.

=head2 FUNCTIONS

=over 4

=item new

ARGS: $cdbi-class, @essential_columns
RETURNS: $self

=item set_essential
ARGS: $self, @essential_columns
RETURNS: @old_essential_columns

change the essential columns again

=item reset_essential
ARGS: $self
RETURNS: @old_essential_columns

revert the essential columns to the original one

=back

=head2 EXPORT

None by default.

=head2 BUGS / CAVEATS

When using several temp-essential columns on the same class on the same time, 
the user has to make sure, that the destruction work in reverse order to 
construction, i.e.

  my $tmp1 = new Class::DBI::TempEssential($cdbi_table,@new_essential1);
  my $tmp2 = new Class::DBI::TempEssential($cdbi_table,@new_essential2);
  ...
  undef $tmp2;
  undef $tmp1;

In particular:

  my $tmp = new Class::DBI::TempEssential($cdbi_table,@new_essential1);
  undef $tmp; # important since perl will use different distruction order
  $tmp = new Class::DBI::TempEssential($cdbi_table,@new_essential2);

=head1 AUTHOR

H. Klein, E<lt>H.Klein@gmx.netE<gt>

=head1 SEE ALSO

L<perl>.

=cut
