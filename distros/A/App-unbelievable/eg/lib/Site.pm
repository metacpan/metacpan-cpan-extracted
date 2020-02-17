package Site;
use App::unbelievable;

our $VERSION = '0.1';

get '/' => sub {
    template 'index' => { 'title' => 'Site' };
};

unbelievable;
