package Apache::Wyrd::Site::MySQLIndex;
use strict;
use base qw(Apache::Wyrd::Services::MySQLIndex);
use Apache::Wyrd::Services::SAK qw(:file);
use HTTP::Request::Common;
our $VERSION = '0.98';

=pod

=head1 NAME

Apache::Wyrd::Site::MySQLIndex - Wrapper MySQLIndex for the Site classes

=head1 SYNOPSIS

Sample Implementation:

  use base qw(Apache::Wyrd::Site::MySQLIndex);

  my $dbh = _get_database_handle();

  sub new {
    my ($class) = @_;
    my $init = {
      dbh => $dbh,
      debug => 0,
      attributes => [qw(doctype meta)],
      maps => [qw(meta)]
    };
    return &Apache::Wyrd::Site::Index::new($class, $init);
  }
  
  sub ua {
    return BASENAME::UA->new;
  }
  
  sub skip_file {
    my ($self, $file) = @_;
    return 1 if ($file eq 'test.html');
    return;
  }

=head1 DESCRIPTION

This class extends the Apach::Wyrd::Site::Index class, so check the
documentation of that module for any methods.  It provides an index of
Apache::Wyrd::Site::Page objects (see that module for details) using the
mysql backend instead of BerkeleyDB.

=over

=cut

sub get_children {
	my ($self, $parent, $params) = @_;
	if (!defined($parent)) {
		return [];
	}
	$self->read_db;
	my $sh = $self->db->prepare('select id, tally from _wyrd_index_children where item=?');
	$sh->execute($parent);
	my @ids = ();
	my %rank = ();
	while (my $data_ref = $sh->fetchrow_arrayref) {
		my $id = $data_ref->[0];
		my $rank = $data_ref->[1];
		push @ids, $id;
		$rank{$id} = $rank;
	}
	my @children = $self->get_entry(\@ids);
	foreach my $child (@children) {
		#copy rank to every element of @children in that perl 5.6 way...
		$child->{'rank'} = $rank{$child->{'id'}};
	}
	return \@children;
}

sub lookup {
	#universal lookup mechanism.  Use attribute as well as page path to get a scalar.
	my ($self, $name, $attribute) = @_;
	$self->read_db;
	my ($id, my $new) = $self->get_id($name);
	my $result = undef;
	if ($new) {
		if (not($attribute)) {
			$result = {};
		} else {
			$result = undef;
		}
	}else {
		if ($attribute) {
			my $sh = $self->db->prepare("select $attribute from _wyrd_index where id=?");
			$sh->execute($id);
			if ($sh->err) {
				$result = undef;
			} else {
				($result) = @{$sh->fetchrow_arrayref || []};
			}
		} else {
			$result = $self->get_entry($id);
		}
	}
	$self->close_db;
	return $result;
}

=pod

=back

=head1 BUGS/CAVEATS

Reserves the new method, which it passes unaltered to
Apache::Wyrd::Services::MySQLIndex.  index_site, skip_file, and
purge_missing are obsolete and may be dropped in future versions.  See
Apache::Wyrd::Services::Index for other bugs/warnings.

=cut

sub new {
	return &Apache::Wyrd::Services::MySQLIndex::new(@_);
}

=pod

=head1 AUTHOR

Barry King E<lt>wyrd@nospam.wyrdwright.comE<gt>

=head1 SEE ALSO

=over

=item Apache::Wyrd

General-purpose HTML-embeddable perl object

=item Apache::Wyrd::Services::Index

General-purpose search engine index object

=back

=head1 LICENSE

Copyright 2002-2007 Wyrdwright, Inc. and licensed under the GNU GPL.

See LICENSE under the documentation for C<Apache::Wyrd>.

=cut

1;
