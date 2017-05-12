use Test::More tests => 6;

no warnings 'once';
use Apache::GuessCharset;
use Apache::FakeRequest;
use FileHandle;

@Apache::File::ISA = qw(FileHandle);

package Mock::Apache::Table;
sub get { @{$_[0]->{$_[1]}} }

local *Apache::FakeRequest::finfo = sub {
    FileHandle->new(shift->{filename});
};

local *Apache::FakeRequest::dir_config = sub {
    my $self = shift;
    return @_ ? @{$self->{dir_config}->{$_[0]}}
	: bless $self->{dir_config}, 'Mock::Apache::Table';
};

package main;

{
    my $r = Apache::FakeRequest->new(
	is_main => 1,
	filename => "t/sjis.html",
	content_type => 'text/html',
	dir_config => {
	    GuessCharsetSuspects => [ qw(euc-jp shiftjis 7bit-jis) ],
	},
    );

    my $code = Apache::GuessCharset::handler($r);
    is $code, Apache::Constants::OK, 'status code is OK';
    is $r->content_type, 'text/html; charset=shift_jis', 'encoding is shift_jis';
}

{
    my $r = Apache::FakeRequest->new(
	is_main => 1,
	filename => "t/sjis.html",
	content_type => 'text/plain',
	dir_config => {
	    GuessCharsetSuspects => [ qw(shiftjis) ],
	},
    );

    my $code = Apache::GuessCharset::handler($r);
    is $code, Apache::Constants::OK, 'status code is OK: should work with text/plain';
    is $r->content_type, 'text/plain; charset=shift_jis', 'encoding is shift_jis';
}

{
    my $r = Apache::FakeRequest->new(
	is_main => 1,
	filename => "t",
	content_type => 'text/plain',
	dir_config => {
	    GuessCharsetSuspects => [ qw(shiftjis) ],
	},
    );

    my $code = Apache::GuessCharset::handler($r);
    is $code, Apache::Constants::DECLINED, 'DECLINED for directory';
}

{
    my $r = Apache::FakeRequest->new(
	is_main => 0,
    );

    my $code = Apache::GuessCharset::handler($r);
    is $code, Apache::Constants::DECLINED, 'DECLINED for subreq';
}
