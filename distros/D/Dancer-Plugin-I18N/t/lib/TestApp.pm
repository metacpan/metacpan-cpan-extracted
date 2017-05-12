package t::lib::TestApp;

use Data::Dumper;
use Dancer;
use Dancer::Plugin::I18N;

use I18N::Langinfo qw(DAY_1 DAY_2 DAY_3 DAY_4 DAY_5 DAY_6 DAY_7 langinfo);

our $VERSION = '0.1';

hook before_template => sub {
    my $tokens = shift;
	$tokens->{'day_name'} = sub {
		no strict 'refs';
		return langinfo(&{'DAY_' .$_[0]});
	};
};

get '/' => sub {
    template 'index', {str=>l('hello')};
};

true;
