# Apache::XPP::Cache::Store::File
# ---------------------------------
# $Revision: 1.9 $
# $Date: 2002/01/16 21:06:01 $
# -----------------------------------------------------

=head1 NAME

Apache::XPP::Cache::Store::File - flatfile cache store

=cut

package Apache::XPP::Cache::Store::File;

=head1 SYNOPSIS

...

=head1 REQUIRES

Apache::XPP::Cache::Store
FileHandle
File::stat

=cut

use Carp;
use strict;
use File::stat;
use FileHandle;
use Data::Dumper;
use Apache::XPP::Cache::Store;
use vars qw( @ISA $debug $debuglines );

BEGIN {
	@ISA		= qw( Apache::XPP::Cache::Store );
	$Apache::XPP::Cache::Store::File::REVISION = (qw$Revision: 1.9 $)[-1];
	$Apache::XPP::Cache::Store::File::VERSION = '2.01';
	$debug		= undef;
	$debuglines	= 1;
}

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

Apache::XPP::Cache::Store::File handles the storing of data in flat file form on behalf
of Apache::XPP::Cache.

=head1 METHODS

=over

=item C<new> ( $name, $group, \%instance_data, \$content )

Creates a new File store object. The contents of %instance_data will be placed in the object
as instance data (for Apache request object, etc.).

=cut
sub new {
	my $proto		= shift;
	my $class		= ref($proto) || $proto;
	my $name		= shift;
	my $group		= shift;
	my $instance	= shift;
	
	my $self		= bless( { %{ ref($instance) ? $instance : {} } }, $class );
	my $filename	= $self->location( $name, $group );
	
	$self->name( $name );
	$self->group( $group );
	$self->filename( $filename );
	
	if (my $content = shift) {
		warn "file: setting content ($content) in cache object" . ($debuglines ? '' : "\n") if ($debug >= 2);
		$self->content( $content );
	}
	
	return $self;
} # END constructor new


=item C<location> ( $name, $group )

Returns the fully qualified filename to the store file for the specified name/group pair.
Files are stored by their $name in the directory $group. If the directory $group does
not exist, it will be created with permissions of 0777 (use the C<umask> function to
change these permissions to more desirable ones).

=cut
sub location {
	my $proto		= shift;
	my $class		= ref($proto) || $proto;
	my $name		= shift;
	my $group		= shift;
	
	$name			=~ s#/#_#g;
	$group			=~ s#/#_#g;
	
	my $directory	= join('/', $proto->cachedir, $group);
	unless (-d $directory) {
		warn "file: creating directory '$directory'" . ($debuglines ? '' : "\n") if ($debug);
		if (!mkdir( $directory, 0777 )) {
			warn "Failed to create directory '$directory'! $!";
			return undef;
		}
	}
	
	return $directory . '/' . $name;
} # END method location


=item C<cachedir> (  )

Returns the directory in which file caches are stored.

=cut
sub cachedir {
	my $self		= shift;
	warn "file: cachedir called" . ($debuglines ? '' : "\n") if ($debug >= 2);
	my $cachedir	= ref($self->r) ? $self->r->dir_config('XPPFileCacheDir') : '/tmp/cache';
	$cachedir = $self->r->server_root_relative($cachedir)
		unless( $cachedir =~ /^\// );
	$cachedir		=~ m#^([/.\-\w]*)$#;
	return $1;
} # END method cachedir


=item C<content> ( [ \$content ] )

Sets the store object's content to $content and returns TRUE.
If $content is omitted, returns the content of the store object.

=cut
sub content {
	my $self		= shift;
	my $class		= ref($self) || return undef;
	my $filename	= $self->filename;
	if (my $content = shift) {
		my $fh		= new FileHandle ("> $filename");
		return undef unless ((defined $fh) && (ref($content)));
		print $fh ${ $content };
		$fh->close;
		return 1;
	} else {
		my $fh		= new FileHandle ($filename);
		return undef unless (defined $fh);
		local($/)	= undef;
		return <$fh>;
	}
} # END method content


=item C<is_expired> (  )

Removes the store file.

=cut
sub is_expired {
	my $self		= shift;
	my $class		= ref($self) || return undef;
	my $filename	= $self->filename;
	unlink $filename || warn "file\t: cannot delete file ($filename): $!" . ($debuglines ? '' : "\n");
	return 1;
} # END method is_expired


=item C<mtime> (  )

=item C<mtime> ( $name, $group )

Returns the modification time of the specified store.

=cut
sub mtime {
	my $proto	= shift;
	my $filename;
	if (my $class = ref($proto)) {
		$filename	= $proto->filename;
	} else {
		my $name	= shift;
		my $group	= shift;
		$filename	= $proto->location( $name, $group );
	}
	
	my $st = stat($filename);	# using File::stat
	unless (ref($st) && $st->can('mtime')) {
		warn "file:\tcannot stat file ($filename): $!" . ($debuglines ? '' : "\n") if ($debug);
		return undef;
	}
	return $st->mtime;
} # END method mtime


1;

__END__

=back

=head1 REVISION HISTORY

 $Log: File.pm,v $
 Revision 1.9  2002/01/16 21:06:01  kasei
 Updated VERSION variables to 2.01

 Revision 1.8  2002/01/15 07:34:22  kasei
 From: Pierre Phaneuf <pp@ludusdesign.com>
 Subject: [Xpp-general] small warning fix
 Date: Mon, 14 Jan 2002 21:51:10 -0500
 Message-Id: <3C43991E.571FAC9E@ludusdesign.com>

 Fixes regex range warning.

 Revision 1.7  2000/09/13 21:00:52  dougw
 Small change to line 165.

 Revision 1.6  2000/09/11 20:12:23  david
 Various minor code efficiency improvements.

 Revision 1.5  2000/09/07 19:01:57  dougw
 Pod fixin's


=head1 AUTHORS

Greg Williams <greg@cnation.com>

=head1 SEE ALSO

perl(1).
Apache::XPP
Apache::XPP:Cache

=cut
