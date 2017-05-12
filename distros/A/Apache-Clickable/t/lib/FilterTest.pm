package FilterTest;
# should be separated into Filter testing module.

use strict;
use vars qw(@ISA @EXPORT);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(filters);

# Can't load Apache::File
require FileHandle;
@Apache::File::ISA = qw(FileHandle);

use Apache::FakeRequest;

sub filters {
    my($file, $class, $config) = @_;
    my $r = Apache::FakeRequest->new(
	content_type => 'text/html',
	is_main => 1,
	filename => $file,
    );

    my $out;
    local $^W;
    local *Apache::FakeRequest::print = sub {
	shift;
	$out .= join '', @_;
    };

    if (ref($config) eq 'HASH') {
	no strict 'refs';
	local $^W;		# subroutine redefined warning
	*{"Apache::FakeRequest::dir_config"} = sub {
	    my($r, $cfgkey) = @_;
	    return $config->{$cfgkey};
	};
    }

    no strict 'refs';
    &{$class. "::handler"}($r);
    return $out;
}


1;
