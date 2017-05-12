package Bb::Collaborate::V3::_Content;
use warnings; use strict;

use Mouse;

use Carp;
use Try::Tiny;
use MIME::Base64;
use File::Basename;

extends 'Bb::Collaborate::V3';

=head1 NAME

Bb::Collaborate::V3::_Content - Base class for Presentation and Mulitmedia content

=cut

sub BUILDARGS {
    my $class = shift;
    my $spec = shift;

    my %args;

    if (defined $spec && ! ref($spec) ) {
	#
	# Assume a single string arguments represents the local path of a file
	# to be uploaded.
	#
	my $content_path = $spec;

	open ( my $fh, '<', $content_path)
	    or die "unable to open content file $content_path";

	binmode $fh;
	my $content = do {local $/; <$fh>};

	close $fh;

	die "content file is empty: $content_path"
	    unless length $content;

	my $filename = File::Basename::basename( $content_path );
	croak "unable to determine a basename for content path: $content_path"
	    unless length $filename;

	%args = (
	    filename => $content_path,
	    content => $content,
	);
    }
    elsif (Elive::Util::_reftype($spec) eq 'HASH') {
	%args = %$spec;
    }
    else {
	croak 'usage: '.$class.'->new( filepath | {name => $filename, content => $binary_data, ...} )';
    }

    if ($args{content}) {
	$args{size} ||= length( $args{content} );
    }

    return \%args;
}

sub _freeze {
    my $class = shift;
    my %db_data = %{ shift() };

    my $content = delete $db_data{content};
    my $db_data = $class->SUPER::_freeze( \%db_data );

    if (defined $content) {
	#
	# (a bit of layer bleed here...). Do we need a separate data type
	# for base 64 encoded data?
	#
	require SOAP::Lite;
	$db_data->{content} = SOAP::Data->type('xs:base64Binary' => MIME::Base64::encode_base64($content,'') );
    }

    return $db_data;
}

sub upload {
    my ($class, $spec, %opt) = @_;

    my $command = (delete($opt{command})
		   || 'UploadRepository' . $class->entity_name);

    my %upload_data = %{ $class->BUILDARGS( $spec ) };

    my $connection = delete $opt{connection} || $class->connection
	or die "not connected";

    $upload_data{creatorId} ||= $connection->user;

    my %params = %{delete $opt{param} || {}};

    my %data_params = %{ $class->_freeze({%upload_data, %params}) };

    #
    # work around SAS bug. upload commands apear to be order sensitive
    #
    my @args;
    for (qw<creatorId filename description content size>) {
	push @args, $_ => delete $data_params{$_}
	    if exists $data_params{$_};
    }

    # mop up
    push @args, $_ => $data_params{$_}
        for keys %data_params;

    $connection->check_command($command => 'c');
    my $som = $connection->call($command, @args);
    my @rows = $class->_readback($som, \%upload_data, $connection, %opt);

    my @objs = (map {$class->construct( $_, connection => $connection )}
		@rows);
    #
    # possibly return a list of recurring meetings.
    #
    return wantarray? @objs : $objs[0];
}

sub list {
    my ($self, @args) = @_;

    return $self->SUPER::list(
	@args,
	command => sub {
	    my ($_crud, $params) = @_;
	    my $ent = $self->entity_name;

	    return exists $params->{sessionId} ? "ListSession${ent}": "ListRepository${ent}"
	},
	);
}

sub delete {
    my ($self, %opt) = @_;

    return $self->SUPER::delete( %opt, command => 'RemoveRepository'.$self->entity_name);
}

1;
