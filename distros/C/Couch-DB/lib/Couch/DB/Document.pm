# Copyrights 2024-2025 by [Mark Overmeer].
#  For other contributors see ChangeLog.
# See the manual pages for details on the licensing terms.
# Pod stripped from pm file by OODoc 2.03.
# SPDX-FileCopyrightText: 2024 Mark Overmeer <mark@overmeer.net>
# SPDX-License-Identifier: Artistic-2.0

package Couch::DB::Document;{
our $VERSION = '0.200';
}

use Couch::DB::Util;

use Log::Report 'couch-db';
use Scalar::Util             qw/weaken/;
use MIME::Base64             qw/decode_base64/;
use Devel::GlobalDestruction qw/in_global_destruction/;


sub new(@) { my ($class, %args) = @_; (bless {}, $class)->init(\%args) }

sub init($)
{	my ($self, $args) = @_;
	$self->{CDD_id}    = delete $args->{id};
	$self->{CDD_db}    = my $db = delete $args->{db};
	$self->{CDD_info}  = {};
	$self->{CDD_batch} = exists $args->{batch} ? delete $args->{batch} : $db->batch;
	$self->{CDD_revs}  = my $revs = {};
	$self->{CDD_local} = delete $args->{local};

	$self->{CDD_couch} = $db->couch;
	weaken $self->{CDD_couch};

	if(my $content = delete $args->{content})
	{	$revs->{_new} = $content;
	}

	# The Document is (for now) not linked to its Result source, because
	# that might consume a lot of memory.  Although it may help debugging.
	# weaken $self->{CDD_result} = my $result = delete $args->{result};

	$self->row(delete $args->{row});
	$self;
}

sub DESTROY()
{	my $self = shift;
	$self->{CDD_revs}{_new} || ! in_global_destruction
		or panic "Unsaved new document.";
}

sub _consume($$)
{	my ($self, $result, $data) = @_;
	my $id       = $self->{CDD_id} = delete $data->{_id};
	my $rev      = delete $data->{_rev};

	# Add all received '_' labels to the existing info.
	my $info     = $self->{CDD_info} ||= {};
	$info->{$_}  = delete $data->{$_}
		for grep /^_/, keys %$data;

	my $attdata = $self->{CDD_atts} ||= {};
	if(my $atts = $info->{_attachments})
	{	foreach my $name (keys %$atts)
		{	my $details = $atts->{$name};
			$attdata->{$name} = $self->couch->_attachment($result->response, $name)
				if $details->{follows};

			# Remove sometimes large data
			$attdata->{$name} = decode_base64 delete $details->{data} #XXX need decompression?
				if defined $details->{data};
		}
	}
	$self->{CDD_revs}{$rev} = $data;
	$self;
}


sub fromResult($$$%)
{	my ($class, $result, $data, %args) = @_;
	$class->new(%args, result => $result)->_consume($result, { %$data });
}

#-------------

sub id()      { $_[0]->{CDD_id} }
sub db()      { $_[0]->{CDD_db} }
sub batch()   { $_[0]->{CDD_batch} }
sub couch()   { $_[0]->{CDD_couch} }

sub _pathToDoc(;$)
{	my ($self, $path) = @_;
	if($self->isLocal)
	{	$path and panic "Local documents not supported with path '$path'";
		return $self->db->_pathToDB('_local/' . $self->id);
	}
	$self->db->_pathToDB($self->id . (defined $path ? "/$path" : ''));
}

sub _deleted($)
{	my ($self, $rev) = @_;
	$self->{CDD_revs}{$rev} = {};
	$self->{CDD_deleted} = 1;
}

sub _saved($$;$)
{	my ($self, $id, $rev, $data) = @_;
	$self->{CDD_id} ||= $id;
	$self->{CDD_revs}{$rev} = $data || delete $self->{CDD_revs}{_new};
}


sub row(;$)
{	my $self = shift;
	@_ or return $self->{CDD_row};
	$self->{CDD_row} = shift;
	weaken($self->{CDD_row});
	$self->{CDD_row};
}

#-------------

sub isLocal() { $_[0]->{CDD_local} }


sub isDeleted() { $_[0]->{CDD_deleted} }


sub revision($) { $_[0]->{CDD_revs}{$_[1]} }


sub latest() { $_[0]->revision(($_[0]->revisions)[0]) }


sub revisions()
{	my $revs = $_[0]->{CDD_revs};
	no warnings 'numeric';   # forget the "-hex" part of the rev
	sort {$b <=> $a} keys %$revs;
}


sub rev() { ($_[0]->revisions)[0] }

#-------------

sub _info() { $_[0]->{CDD_info} or panic "No info yet" }


sub conflicts()        { @{ $_[0]->_info->{_conflicts} || [] } }
sub deletedConflicts() { @{ $_[0]->_info->{_deleted_conflicts} || [] } }
sub updateSequence()   { $_[0]->_info->{_local_seq} }


sub revisionsInfo()
{	my $self = shift;
	return $self->{CDD_revinfo} if $self->{CDD_revinfo};

	my $c = $self->_info->{_revs_info}
		or error __x"You have requested the open_revs detail for the document yet.";

	$self->{CDD_revinfo} = +{ map +($_->{rev} => $_), @$c };
}


sub revisionInfo($) { $_[0]->revisionsInfo->{$_[1]} }

#-------------

sub exists(%)
{   my ($self, %args) = @_;

    $self->couch->call(HEAD => $self->_pathToDoc,
        $self->couch->_resultsConfig(\%args),
    );
}


sub __created($$)
{	my ($self, $result, $data) = @_;
	$result or return;

	my $v = $result->values;
	$v->{ok} or return;

	delete $data->{_id};  # do not polute the data
	$self->_saved($v->{id}, $v->{rev}, $data);
}
	
sub create($%)
{	my ($self, $data, %args) = @_;
	ref $data eq 'HASH' or panic "Attempt to create document without data.";

	my %query;
	$query{batch} = 'ok'
		if exists $args{batch} ? delete $args{batch} : $self->batch;

	# When the _id is (accidentally) undef, no new one will be picked
	$data->{_id} ||= $self->id;
	defined $data->{_id} or delete $data->{_id};

	$self->couch->call(POST => $self->db->_pathToDB,  # !!
		send     => $data,
		query    => \%query,
		$self->couch->_resultsConfig(\%args,
			on_final => sub { $self->__created($_[0], $data) },
		),
	);
}


sub update($%)
{	my ($self, $data, %args) = @_;
	ref $data eq 'HASH' or panic "Attempt to update the document without data.";

	my $couch     = $self->couch;

	my %query;
	$query{batch} = 'ok' if exists $args{batch} ? delete $args{batch} : $self->batch;
	$query{rev}   = delete $args{rev} || $self->rev;
	$query{new_edits} = delete $args{new_edits} if exists $args{new_edits};
	$couch->toQuery(\%query, bool => qw/new_edits/);

	$couch->call(PUT => $self->_pathToDoc,
		query    => \%query,
		send     => $data,
		$couch->_resultsConfig(\%args, on_final => sub { $self->__created($_[0], $data) }),
	);
}


sub __get($$)
{	my ($self, $result, $flags) = @_;
	$result or return;   # do nothing on unsuccessful access
	$self->_consume($result, $result->answer);

	# meta is a shortcut for other flags
	$flags->{conflicts} = $flags->{deleted_conflicts} = $flags->{revs_info} = 1
		if $flags->{meta};

	$self->{CDD_flags}      = $flags;
}

sub get(%)
{	my ($self, $flags, %args) = @_;
	my $couch = $self->couch;

	my %query  = $flags ? %$flags : ();
	$couch->toQuery(\%query, bool => qw/attachments att_encoding_info conflicts
		deleted_conflicts latest local_seq meta revs revs_info/);

	$couch->call(GET => $self->_pathToDoc,
		query    => \%query,
		$couch->_resultsConfig(\%args,
			on_final => sub { $self->__get($_[0], $flags) },
			_headers => { Accept => $args{attachments} ? 'multipart/related' : 'application/json' },
		),
	);
}


sub __delete($)
{	my ($self, $result) = @_;
	$result or return;

	my $v = $result->values;
	$self->_deleted($v->{rev}) if $v->{ok};
}

sub delete(%)
{	my ($self, %args) = @_;
	my $couch = $self->couch;

	my %query;
	$query{batch} = 'ok' if exists $args{batch} ? delete $args{batch} : $self->batch;
	$query{rev}   = delete $args{rev} || $self->rev;
		
	$couch->call(DELETE => $self->_pathToDoc,
		query    => \%query,
		$couch->_resultsConfig(\%args, on_final => sub { $self->__delete($_[0]) }),
	);
}


# Not yet implemented.  I don't like chaning the headers of my generic UA.
sub cloneInto($%)
{	my ($self, $to, %args) = @_;
	my $couch = $self->couch;

	my %query;
	$query{batch} = 'ok' if exists $args{batch} ? delete $args{batch} : $self->batch;
	$query{rev}   = delete $args{rev} || $self->rev;

#XXX still work to do on updating the admin in 'to'
	$couch->call(COPY => $self->_pathToDoc,
		query    => \%query,
		$couch->_resultsConfig(\%args,
			on_final => sub { $self->__delete($_[0]) },
			_headers => +{ Destination => $to->id },
		),
	);
}


sub appendTo($%)
{	my ($self, $to, %args) = @_;
	my $couch = $self->couch;

	my %query;
	$query{batch} = 'ok' if exists $args{batch} ? delete $args{batch} : $self->batch;
	$query{rev}   = delete $args{rev} || $self->rev;

#XXX still work to do on updating the admin in 'to'
	my $dest_rev  = $to->rev or panic "No revision for destination document.";

	$couch->call(COPY => $self->_pathToDoc,
		query    => \%query,
		$couch->_resultsConfig(\%args,
			on_final => sub { $self->__delete($_[0]) },
			_headers => +{ Destination => $to->id . "?rev=$dest_rev" },
		),
	);
}


#-------------

sub attInfo($)    { $_[0]->_info->{_attachments}{$_[1]} }
sub attachments() { keys %{$_[0]->_info->{_attachments}} }
sub attachment($) { $_[0]->{CDD_atts}{$_[1]} }


sub attExists($%)
{	my ($self, $name, %args) = @_;
	my %query = ( rev => delete $args{rev} || $self->rev );

	$self->couch->call(HEAD => $self->_pathToDoc($name),
		query => \%query,
		$self->couch->_resultsConfig(\%args),
	);
}


sub __attLoad($$)
{	my ($self, $result, $name) = @_;
	$result or return;
	my $data = $self->couch->_messageContent($result->response);
	$self->_info->{_attachments}{$name} = { length => length $data };
	$self->{CDD_atts}{$name} = $data;
}

sub attLoad($%)
{	my ($self, $name, %args) = @_;
	my %query = ( rev => delete $args{rev} || $self->rev );

	$self->couch->call(GET => $self->_pathToDoc($name),
		query => \%query,
		$self->couch->_resultsConfig(\%args,
			on_final => sub { $self->__attLoad($_[0], $name) },
		),
	);
}


sub attSave($$%)
{	my ($self, $name, $data, %args) = @_;

	my  $type = delete $args{type} || 'application/octet-stream';
	my %query = (rev => delete $args{rev} || $self->rev);
	$query{batch} = 'ok' if exists $args{batch} ? delete $args{batch} : $self->batch;

	$self->couch->call(PUT => $self->_pathToDoc($name),
		query => \%query,
		send  => $data,
		$self->couch->_resultsConfig(\%args,
			_headers => { 'Content-Type' => $type },
		),
	);
}


sub attDelete($$$%)
{	my ($self, $name, %args) = @_;
	my %query = (rev => delete $args{rev} || $self->rev);
	$query{batch} = 'ok' if exists $args{batch} ? delete $args{batch} : $self->batch;

	$self->couch->call(DELETE => $self->_pathToDoc($name),
		query => \%query,
		$self->couch->_resultsConfig(\%args),
	);
}

1;
