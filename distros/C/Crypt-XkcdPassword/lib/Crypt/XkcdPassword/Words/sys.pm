use 5.008;
use strict;
use warnings;
use utf8;

package Crypt::XkcdPassword::Words::sys;

BEGIN {
	$Crypt::XkcdPassword::Words::sys::AUTHORITY = 'cpan:TOBYINK';
	$Crypt::XkcdPassword::Words::sys::VERSION   = '0.009';
}

use File::Spec;
use Types::Standard 1.000000 qw( Str );

use Moo 1.006000;
with qw(Crypt::XkcdPassword::Words);

my $AbsFile = Str
	-> where(sub { File::Spec::->file_name_is_absolute($_) })
	-> plus_coercions(Str, sub { "/usr/share/dict/$_" });

has filename => (
	is      => "rw",
	isa     => $AbsFile,
	default => '/usr/share/dict/words',
	coerce  => 1,
);

around BUILDARGS => sub
{
	my $next = shift;
	my $self = shift;
	
	return $self->$next(filename => $_[0])
		if @_==1 and not ref $_[0];
	
	$self->$next(@_);
};

sub description
{
	"Uses the words list from /usr/share/dict";
}

sub filehandle
{
	my $self = shift;
	
	my $name = $self->filename;
	-f $name or croak("$name does not exist; bailing out");

	open my $fh, '<:utf8', $name;
	$fh;
}

sub cache_key
{
	my $self = shift;
	join("~", ref($self), $self->filename);
}

__PACKAGE__
