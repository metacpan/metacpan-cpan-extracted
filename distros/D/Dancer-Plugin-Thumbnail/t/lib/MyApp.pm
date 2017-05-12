package MyApp;

use FindBin;
use Dancer;
use Dancer::Plugin::Thumbnail;

set public => path $FindBin::RealBin, 'public';


# just '200 OK'
get '/' => sub {
	'OK';
};

# send an original file
get '/original' => sub {
	send_file 'lonerr.jpg';
};

# resize
get '/resize/:w/:h/:s' => sub {
	thumbnail 'lonerr.jpg' => [
		resize => { w => param('w'), h => param('h'), s => param('s') }
	];
};
get '/resize/:w/:h' => sub {
	thumbnail 'lonerr.jpg' => [
		resize => { w => param('w'), h => param ('h') }
	];
};
get '/sresize/:w/:h' => sub {
	resize 'lonerr.jpg' => { w => param('w'), h => param ('h') };
};


# crop
get '/crop/:w/:h/:a' => sub {
	thumbnail 'lonerr.jpg' => [
		crop => { w => param('w'), h => param('h'), a => param('a') }
	];
};
get '/crop/:w/:h' => sub {
	thumbnail 'lonerr.jpg' => [
		crop => { w => param('w'), h => param ('h') }
	];
};
get '/scrop/:w/:h' => sub {
	crop 'lonerr.jpg' => { w => param('w'), h => param ('h') };
};


# format
get '/format/:w/:h/:f' => sub {
	thumbnail 'lonerr.jpg' => [
		resize => { w => param('w'), h => param('h') }
	], { format => param('f') };
};


# quality
get '/quality/:w/:h/:q' => sub {
	thumbnail 'lonerr.jpg' => [
		resize => { w => param('w'), h => param('h') }
	], { format => 'jpeg', quality => param('q') }
};

# compression
get '/compression/:w/:h/:c' => sub {
	thumbnail 'lonerr.jpg' => [
		resize => { w => param('w'), h => param('h') }
	], { format => 'png', compression => param('c') }
};

# multiple
get '/multiple/1' => sub {
	thumbnail 'lonerr.jpg' => [
		resize => { w => '100' },
		crop   => { h => '25', a => 'lt' },
	], { quality => 60 }
};
get '/multiple/2' => sub {
	thumbnail 'lonerr.jpg' => [
		crop   => { h => '25', a => 'lt' },
		resize => { w => '100' },
	], { format => 'png', compression => 5 }
};


true;

