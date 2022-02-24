package UserAgent;
use warnings;
use strict;
use File::Spec;

use lib './t';
use Fixture 'read_html';

sub new {
    my ($class, $version) = @_;
    my $self = {
        name => 'fake user agent',
        version => $version,
        response_dir => 'sequence'
        };
    bless $self, $class;
    return $self;
}

sub _response_path {
    my ($self, $filename) = @_;
    return File::Spec->catfile(($self->{response_dir}), $filename);
}

sub login {
    my $self = shift;
    return read_html($self->_response_path('1.html'));
}

sub spam_report {
    my $self = shift;
    return read_html($self->_response_path('2.html'));
}

sub complete_report {
    my $self = shift;
    return read_html($self->_response_path('3.html'));
}

sub base {
    return 'https://www.spamcop.net/sc?id=z6731356012zdc1bc09296ac2635b0861f61911073e5z';
}

1;
