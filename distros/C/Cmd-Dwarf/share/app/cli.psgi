use Plack::Handler::CLI;
use App;

Plack::Handler::CLI->new(need_headers => 0)->run(
	sub {
		App->new(env => shift)->to_psgi;
	},
	\@ARGV
);
