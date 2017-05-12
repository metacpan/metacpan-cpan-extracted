# Listman.pm - this file is part of the CGI::Listman distribution
#
# CGI::Listman is Copyright (C) 2002 iScream multimédia <info@iScream.ca>
#
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Author: Wolfgang Sourdeau <Wolfgang@Contre.COM>

use strict;

package CGI::Listman;

use Carp;
use DBI;

use CGI::Listman::dictionary;
use CGI::Listman::line;
use CGI::Listman::selection;

use vars qw($VERSION);
$VERSION = '0.05';

=pod

=head1 NAME

CGI::Listman - Easily managing web subscribtion lists

=head1 SYNOPSIS

    use CGI::Listman;

=head1 DESCRIPTION

CGI::Listman provides an object-oriented interface to easily manage
web-based subscribtion lists. It implements concepts such as
"dictionaries", "selections", "exporters", provides some checking
facilities (field duplication or requirements) and uses the DBI interface
so as to provide a backend-independent storage area (PostgreSQL, ...).

The I<CGI::Listman> class manages the listmanagers of your project. This
is the very first class you want to instantiate. It is the logical
central point of all others objects. Except for I<CGI::Listman::line>,
I<CGI::Listman::exporter> and I<CGI::Listman::selection>, you should not
call any other class's "new" method since I<CGI::Listman> will handle its
own instances for you.

=head1 API

=head2 new

As for any perl class, new acts as the constructor for an instance of this
class. It has three optional arguments that, if not specified, can be
replaced with calls to the respective methods: I<set_backend>,
I<set_list_name>, I<set_list_directory>.

=over

=item Parameters

All the parameters are optional with this method.

=over

=item backend

A string representing the I<DBI> backend to be used. (Warning: only "CSV"
and "mysql" are supported at this time.)

=item list filename

A string representing the base filename for the dictionary and the
storage file (for the CVS backend).

=item list directory

A string representing the directory where the list data will be stored.

=back

=item Return values

A reference to a blessed instance of I<CGI::Listman>.

=item Examples

=over

=item 1

    my $list_manager = CGI::Listman->new; # creates a simple list
                                          # manager without any
                                          # arguments

=item 2

    # creates a list manager by specifying the backend, the filename
    # and the storage directory
    my $list_manager = CGI::Listman->new ('CSV', 'userlist', '/var/lib/weblists');

=back

=back

=cut

sub new {
  my $class = shift;

  my $self = {};
  $self->{'dbi_backend'} = shift;
  $self->{'list_name'} = shift;
  $self->{'list_dir'} = shift;
  $self->{'table_name'} = $self->{'list_name'};
  $self->{'db_name'} = undef;
  $self->{'db_uname'} = undef;
  $self->{'db_passwd'} = undef;
  $self->{'db_host'} = undef;
  $self->{'db_port'} = undef;

  $self->{'list'} = undef;
  $self->{'_dbi_params'} = undef;
  $self->{'_dictionary'} = undef;
  $self->{'_last_line_number'} = 0;
  $self->{'_loading_list'} = undef;

  bless $self, $class;
}

=pod

=head2 set_backend

Defines the DBI backend used to store the list data.

=over

=item Parameters

=over

=item backend

A string representing the I<DBI> backend. As noted before only 'CSV' and
'mysql' are currently supported. More will be supported in the future.

=back

=item Return values

This method returns nothing.

=back

=cut

sub set_backend {
  my ($self, $backend) = @_;

  if (defined $self->{'dbi_backend'}) {
    croak "A backend is already defined ("
      .$self->{'dbi_backend'}.") for this CGI::Listman instance.\n"
  } else {
    eval "use DBD::".$backend.";";
    croak "This backend is not available:\n".$@ if ($@);
    $self->{'dbi_backend'} = $backend;
  }
}

=pod

=head2 set_db_name

Defines the database where the list data has to be stored.

=over

=item Parameters

=over

=item db_name

A string representing the database name. This information is required for
non-file-based storage databases.

=back

=item Return values

This method returns nothing.

=back

=cut

sub set_db_name {
  my ($self, $db_name) = @_;

  croak "A database is already defined  (".$self->{'db_name'}
    .") for this CGI::Listman instance.\n"
      if (defined $self->{'db_name'} && $self->{'db_name'} ne '');

  $self->{'db_name'} = $db_name;
}

=pod

=head2 set_user_infos

Defines the username and password needed to connect to the database.

=over

=item Parameters

=over

=item username

A string representing the username.

=item password

A string representing the password.

=back

=item Return values

This method returns nothing.

=back

=cut

sub set_user_infos {
  my ($self, $db_uname, $db_passwd) = @_;

  croak "A password is already defined for this CGI::Listman instance.\n"
    if (defined $self->{'db_passwd'} && $self->{'db_passwd'} ne '');
  croak "A username is already defined (".$self->{'db_uname'}
    .") for this CGI::Listman instance.\n"
      if (defined $self->{'db_uname'} && $self->{'db_uname'} ne '');

  $self->{'db_uname'} = $db_uname;
  $self->{'db_passwd'} = $db_passwd;
}

=pod

=head2 set_host_infos

Defines the hostname and port where the database resides. The use of this
function might not absolutely be needed. For example, the "mysql" backend
default's host is "localhost". So if your database is stored on the same
machine as your webserver, you will not need to use this function.

=over

=item Parameters

=over

=item hostname

A string representing the hostname of the machine your database engine is
running on.

=item port

An integer representing the TCP/IP port your database daemon is listening on.

=back

=item Return values

This method returns nothing.

=back

=cut

sub set_host_infos {
  my ($self, $db_host, $db_port) = @_;

  croak "A hostname/address is already defined  (".$self->{'db_host'}
    .") for this CGI::Listman instance.\n"
      if (defined $self->{'db_host'} && $self->{'db_host'} ne '');
  croak "A port is already defined (".$self->{'db_port'}
    .") for this CGI::Listman instance.\n"
      if (defined $self->{'db_port'} && $self->{'db_port'} ne '');

  $self->{'db_host'} = $db_host;
  $self->{'db_port'} = $db_port;
}

=pod

=head2 set_list_name

Gives a name to your list.

=over

=item Parameters

=over

=item name

A string representing the name of your list, which it turns define the
base name for various storage files. The name of the list's dictionary
(see L<CGI::Listman::dictionary>) will be deduced from it as well as its
CSV "database" file if ever.

=back

=item Return values

This method returns nothing.

=back

=cut

sub set_list_name {
  my ($self, $list_name) = @_;

  croak "A list name is already defined (".$self->{'list_name'}
    .") for this instance of CGI::Listman.\n"
      if (defined $self->{'list_name'});

  $self->{'list_name'} = $list_name;
  $self->{'table_name'} = $list_name
    unless (defined $self->{'table_name'});
}

=pod

=head2 set_list_directory

Defines where the list's dictionary and data files are stored.

=over

=item Parameters

=over

=item directory

A string representing the directory where this instance of
I<CGI::Listman> will have its data files stored.

=back

=item Return values

This method returns nothing.

=back

=cut

sub set_list_directory {
  my ($self, $new_directory) = @_;

  croak "A list directory is already defined (".$self->{'list_name'}
    .") for this instance of CGI::Listman.\n"
      if (defined $self->{'list_dir'});
  $self->{'list_dir'} = $new_directory;
}

=pod

=head2 set_table_name

For "real" (i.e. everything except "CSV") database backends, gives the
name of the table the list is stored into. If not called, the list name
will be used.

=over

=item Parameters

=over

=item table name

A string representing the table name of your list for use with databases.

=back

=item Return values

This method returns nothing.

=back

=cut

sub set_table_name {
  my ($self, $table_name) = @_;

  croak "Please defined a list_name before a table_name.\n"
    unless (defined $self->{'table_name'});

  croak "The table_name cannot be empty.\n"
    if ('table_name' eq '');
  $self->{'table_name'} = $table_name;
}

=pod

=head2 dictionary

Obtain the dictionary of this instance (there is only one dictionary for
each instance). This method will automatically create and read the list's
dictionary for you if needed.

=over

=item Parameters

This method takes no parameter.

=item Return values

A reference to an instance of I<CGI::Listman::dictionary>.

=back

=cut

sub dictionary {
  my $self = shift;

  unless (defined $self->{'_dictionary'}) {
    croak "List directory not defined for this instance of CGI::Listman.\n"
      unless (defined $self->{'list_dir'});
    croak "List filename not defined for this instance of CGI::Listman.\n"
      unless (defined $self->{'list_name'});

    my $path = $self->{'list_dir'}.'/'.$self->{'list_name'}.'.dict';
    croak "No dictionary ('".$self->{'list_name'}.".dict')\n"
      unless (-f $path);

    my $dictionary = CGI::Listman::dictionary->new ($path);

    $self->{'_dictionary'} = $dictionary;
  }

  return $self->{'_dictionary'};
}

=pod

=head2 seek_line_by_num

Returns the n'th I<CGI::Listman::line> of this instance.

=over

=item Parameters

=over

=item number

An integer representing the requested I<CGI::Listman::line>.

=back

=item Return values

A reference to an instance of I<CGI::Listman::line>.

=back

=cut

sub seek_line_by_num {
  my ($self, $number) = @_;

  $self->load_lines () unless (defined $self->{'list'});

  my $ret_line = undef;
  my $list_ref = $self->{'list'};

  foreach my $line (@$list_ref) {
    if ($line->number () == $number) {
      $ret_line = $line;
      last;
    }
  }

  return $ret_line;
}

=pod

=head2 add_line

Add a I<CGI::Listman::line> (see L<CGI::Listman::line> to this instance's
list of lines.

=over

=item Parameters

=over

=item line

An instance of I<CGI::Listman::line> to be added to this list manager.

=back

=item Return values

This method returns nothing.

=back

=cut

sub add_line {
  my ($self, $line) = @_;

  $self->load_lines ()
    unless (defined $self->{'list'}
	    || defined $self->{'_loading_list'});

  $line->{'number'} = $self->{'_last_line_number'} + 1
    unless ($line->{'number'});

  my @numbers = $self->_get_line_numbers ();
  croak "This instance's list of lines already contains a line with"
    ." this number (".$line->{'number'}.").\n"
      if (grep (m/$line->{'number'}/, @numbers));

  $self->{'_last_line_number'} = $line->{'number'};

  unless (defined $self->{'list'}) {
    my @new_list;
    $self->{'list'} = \@new_list;
  }

  my $list_ref = $self->{'list'};
  push @$list_ref, $line;
}

=pod

=head2 load_lines

Loads the line from the list database or storage file. This function is
deprecated and will probably be removed or made private in a later
release.

=over

=item Parameters

This method takes no argument.

=item Return values

This method returns nothing.

=back

=cut

sub load_lines {
  my $self = shift;

  $self->{'_loading_list'} = 1;
  $self->_db_connect ();

  my $dbh = $self->{'_db_connection'};

  my $row_list =
    $dbh->selectall_arrayref ("SELECT * FROM ".$self->{'table_name'})
    or croak $dbh->errstr;

# croak $row_list->[0];
  delete $self->{'list'} if (defined $self->{'list'});

  if (defined $row_list) {
    foreach my $row (@$row_list) {
      my $line = CGI::Listman::line->new ();
      $line->_build_from_listman_data ($row);
      $self->add_line ($line);
    }
  }

  $self->{'_loading_list'} = undef;
}

=pod

=head2 list_contents

Returns a reference to an ARRAY of the list's lines. This method takes
care of preloading the list from the database if needed.

=over

=item Parameters

This method takes no argument.

=item Return values

A reference to the ARRAY of I<CGI::Listman::line> of this list manager
object.

=back

=cut

sub list_contents {
  my $self = shift;

  my $contents_ref = undef;
  if (defined $self->{'list'}) {
    my @filt_contents;
    my $old_cref = $self->{'list'};
    foreach my $line (@$old_cref) {
      push @filt_contents, $line
	if (!$line->{'_deleted'});
    }
    $contents_ref = \@filt_contents;
  } else {
    $self->load_lines ();
    $contents_ref = $self->{'list'};
  }

  return $contents_ref;
}

=pod

=head2 check_params

This method checks the presence in the hash ref of keys that are marked
as mandatory in the instance's dictionary. It returns two ARRAY
references, the first of which lists the missing mandatory fields, the
second being a list of the fields that are not present in the dictionary.

=over

=item Parameters

=over

=item fields_hashref

A reference to a HASH whereof the keys are the names CGI fields.

=back

=item Return values

=over

=item missing_arrayref

A reference to an array of mandatory fields (see
L<CGI::Listman::dictionary::term> that were missing from
I<parameters_hashref>.

=item unknown_arrayref

A reference to an array of "unknown fields". That is, fields that were
part of I<parameters_hashref> but that were not found in the dictionary.

=back

=back

=cut

# Check the validity of received parameters and returns two refs against
# the missing mandatory values and the unknown fields.
sub check_params {
  my ($self, $param_hash_ref) = @_;

  my $dictionary = $self->dictionary ();

  my @missing;
  my @unknown;

  foreach my $key (keys %$param_hash_ref) {
    my $term = $dictionary->get_term ($key);
    push @unknown, $key
      unless (defined $term);
  }

  my $dict_terms = $dictionary->terms ();

  foreach my $term (@$dict_terms) {
    my $key = $term->{'key'};
    push @missing, $term->definition_or_key ()
      if ($term->{'mandatory'}
	  && (!defined $param_hash_ref->{$key}
	      || $param_hash_ref->{$key} eq ''));
  }

  return (\@missing, \@unknown);
}

=pod

=head2 commit

This method commits any changes made to your instance, after which, that
instance will be invalidated. As long as it is not called, you can of
course apply any modifications to your instance. This limitation will
probably be got rid of in a next release.

=over

=item Parameters

This method takes no argument.

=item Return values

This method returns nothing.

=back

=cut

sub commit {
  my $self = shift;

  croak "Commit again?\n"
    if (defined $self->{'_commit'});

  if (defined $self->{'list'}) {
    $self->_db_connect ();
    my $dbh = $self->{'_db_connection'};
    my $list_ref = $self->{'list'};
    foreach my $line (@$list_ref) {
      if ($line->{'_updated'}) {
	next if ($line->{'_deleted'} && $line->{'_new_line'});
	if ($line->{'_deleted'}) {
	  $dbh->do ("DELETE FROM ".$self->{'table_name'}.
		    "       WHERE number = ".$line->{'number'})
	    or croak "A DBI error occured while deleting line "
	      .$line->{'number'}." from ".$self->{'table_name'}
		.":\n".$dbh->errstr;
	} elsif ($line->{'_new_line'}) {
	  $line->{'timestamp'} = time ()
	    unless ($line->{'timestamp'});
	  my $record = $self->_prepare_record ($line);
	  my $sth = $dbh->do ("INSERT INTO ".$self->{'table_name'}.
				   "       VALUES (".$record.")")
	    or croak "A DBI error occured while inserting...\n".$record.
	      "... into ".$self->{'table_name'}.":\n".$dbh->errstr;
	} else {
	  $dbh->do ("DELETE FROM ".$self->{'table_name'}.
		    "       WHERE number = ".$line->{'number'})
	    or croak "A DBI error occured while deleting line "
	      .$line->{'number'}." from ".$self->{'table_name'}
		.":\n".$dbh->errstr;
	  my $record = $self->_prepare_record ($line);
	  my $sth = $dbh->do ("INSERT INTO ".$self->{'table_name'}.
				   "       VALUES (".$record.")")
	    or croak "A DBI error occured while inserting...\n".$record.
	      "... into ".$self->{'table_name'}.":\n".$dbh->errstr;
	}
      }
    }
    $dbh->disconnect ();
  }

  $self->{'_commit'} = 1;
}

=pod

=head2 delete_line

Delete a I<CGI::Listman::line> from this instance's list of lines.

=over

=item Parameters

An instance of I<CGI::Listman::line> to be removed from this list manager.

=item Return values

This method returns nothing.

=back

=cut

sub delete_line {
  my ($self, $line) = @_;

  croak "Cannot delete a line with number equal to 0.\n"
    unless ($line->{'number'});

  my $list_ref = $self->{'list'};
  croak "List empty.\n" unless (defined $list_ref);

  # delete the line from the list in memory...
  my $count;
  for ($count = 0; $count < @$list_ref; $count++) {
    if ($list_ref->[$count] == $line) {
      $line->{'_updated'} = 1;
      $line->{'_deleted'} = 1;
      last;
    }
  }

  croak "Line not found in list."
    if ($count == @$list_ref);
}

=pod

=head2 delete_selection

Delete many lines at the same time through the use of a
I<CGI::Listman::selection> (see L<CGI::Listman::selection>).

=over

=item Parameters

An instance of I<CGI::Listman::selection> made of lines to be removed
from this list manager.

=item Return values

This method returns nothing.

=back

=cut

sub delete_selection {
  my ($self, $selection) = @_;

  my $list_ref = $selection->{'list'};
  croak "Selection is empty.\n" unless ($list_ref);
  foreach my $line (@$list_ref) {
    $self->delete_line ($line);
  }
}

# the private methods begin here

sub _prepare_record {
  my ($self, $line) = @_;

  my $fields_ref = $line->line_fields ();
  my @records;
  push @records, ($line->{'timestamp'}, $line->{'seen'}, $line->{'exported'});
  push @records, @$fields_ref;

  my $record_line = "'".$line->{'number'}."'";
  foreach my $record (@records) {
    $record =~ s/\'/\\\'/g;
    $record = '' unless (defined $record);
    $record_line .= ", '".$record."'";
  }

  # if we don't untaint $record_line, we get a stange error regarding
  # DBD::SQL::Statement::HASH_ref...
  $record_line =~ m/(.*)/;
  $record_line = $1;

  return $record_line;
}

sub _dbi_setup {
  my $self = shift;

  unless (defined $self->{'_dbi_params'}) {
    croak "No backend specified for this instance of CGI::Listman.\n"
      unless (defined $self->{'dbi_backend'});
    if ($self->{'dbi_backend'} eq 'CSV') {
      $self->{'_dbi_params'} = ":f_dir=".$self->{'list_dir'};
      unless (-f $self->{'list_dir'}.'/'.$self->{'table_name'}.'.csv') {
	open my $list_file, '>'
	  .$self->{'list_dir'}.'/'.$self->{'table_name'}.'.csv';
	close $list_file;
      }
    } else {
      croak "Sorry, the DBI backend \"".$self->{'dbi_backend'}
	."\" is not handled at this time.\n"
	  unless ($self->{'dbi_backend'} eq 'mysql');
      my $dbi_params = ":database=".$self->{'db_name'};
      $dbi_params .= ":host=".$self->{'db_host'}
      	if (defined $self->{'db_host'} && $self->{'db_host'} ne '');
      $dbi_params .= ":port=".$self->{'db_port'}
	if (defined $self->{'db_port'} && $self->{'db_port'} ne '');
      $self->{'_dbi_params'} = $dbi_params;
    }
  }
}

sub _db_fields_setup {
  my $self = shift;

  unless (defined $self->{'_db_fields'}) {
    my @fields = ('number', 'timestamp', 'seen', 'exported');
    my $dictionary = $self->dictionary ();
    my $dict_terms = $dictionary->terms ();

    foreach my $term (@$dict_terms) {
      push @fields, $term->{'key'};
    }
    $self->{'_db_fields'} = \@fields;
  }
}

sub _db_connect {
  my $self = shift;

  unless (defined $self->{'_db_connection'}) {
    $self->_dbi_setup ();
    $self->_db_fields_setup ();
    my $dbh = DBI->connect ("DBI:"
			    .$self->{'dbi_backend'}.$self->{'_dbi_params'},
			    $self->{'db_uname'},
			    $self->{'db_passwd'})
    or croak DBI->errstr;
    if ($self->{'dbi_backend'} eq 'CSV') {
      $dbh->{'csv_tables'}->{$self->{'table_name'}} =
	{'col_names' => $self->{'_db_fields'},
	 'file' => $self->{'table_name'}.".csv"};
    }
    $self->{'_db_connection'} = $dbh;
  }
}

sub _get_line_numbers {
  my $self = shift;

  my @numbers;

  if (defined $self->{'list'}) {
    my $list_ref = $self->{'list'};

    foreach my $line (@$list_ref) {
      push @numbers, $line->number ();
    }
  }

  return @numbers;
}

1;

__END__

=pod

=head1 AUTHOR

Wolfgang Sourdeau, E<lt>Wolfgang@Contre.COME<gt>

=head1 COPYRIGHT

Copyright (C) 2002 iScream multimédia <info@iScream.ca>

This package is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<CGI::Listman::line(3)> L<CGI::Listman::exporter(3)>
L<CGI::Listman::dictionary(3)> L<CGI::Listman::dictionary::term(3)>
L<CGI::Listman::selection(3)>

L<DBI(3)>, L<CGI(3)>

=cut
