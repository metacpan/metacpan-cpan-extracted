package tagtest;
use Dancer ':syntax';
use lib '../../lib';
use Dancer::Plugin::TagHelper;

our $VERSION = '0.1';

get '/' => sub {
    template 'index';
#    return setting('template');
};

true;
