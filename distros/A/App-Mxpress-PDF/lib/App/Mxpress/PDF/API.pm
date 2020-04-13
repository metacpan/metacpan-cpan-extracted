package App::Mxpress::PDF::API;

use Dancer2 appname => 'App::Mxpress::PDF';

use Dancer2::Plugin::CSRF::SPA;

use Mxpress::PDF;
use MetaCPAN::CLient::Pod::PDF;
use Type::Params qw/compile_named/;
use Types::Standard qw/Str StrMatch Enum HashRef/;

prefix '/api';

set 'database' => File::Spec->catfile(File::Spec->tmpdir(), 'dancr.db');
set 'session' => 'Simple';

hook before => sub {
      if ( request->is_post() ) {
	      my $csrf_token = request_header('Token');
	      if ( !$csrf_token || !validate_csrf_token($csrf_token) ) {
			die 'Invalid CSRF';
	      }
      }
};

hook after => sub {
	if ( request->is_post() ) {
		response_headers 'Token' => get_csrf_token();
	}
};

our $login = compile_named(
	username => Types::Standard::Optional->of(Str),
	password => Types::Standard::Optional->of(Str)
);

post '/login' => sub {
	my $body = $login->(
		decode_json(request->body)
	);

	my %res = ();
	if ($body->{username} && $body->{password}) {
		if ($body->{username} ne setting('username')) {
			$res{error} = 'Invalid username';
		} elsif ($body->{password} ne setting('password')) {
			$res{error} = 'Invalid password';
		} else {
			session 'logged_in' => true;
			$res{success} = 'You have logged in.';
		}
	}
	
	return encode_json(\%res);
};

post '/logout' => sub {
	app->destroy_session;
	return encode_json({ success => 'User has logged out.' });
};

get '/session' => sub {
	# check whether we have a session
	response_headers 'Token' => get_csrf_token();
	return encode_json({ 
		session => session->data->{logged_in} ? 1 : 0 
	});
};

our $generatePOD = compile_named(
	styles => Str,
	'pod-type' => Enum[qw/module distribution raw/],
	name => StrMatch[ qr{([a-zA-Z0-9\-\:]+)} ],
	module => Types::Standard::Optional->of(StrMatch[ qr{([a-zA-Z0-9\-\:]*)} ]),
	distribution => Types::Standard::Optional->of(StrMatch[ qr{([a-zA-Z0-9\-\:]*)} ],),
	raw => Types::Standard::Optional->of(Str)
);

post '/generate/pod' => sub {
	if ( not session('logged_in') ) {
        	send_error("Not logged in", 401);
    	}

	my $body = $generatePOD->(
		decode_json(request->body)
	);
	
	my $styles = decode_json($body->{styles}) || {};

	my $client = MetaCPAN::Client::Pod::PDF->new();

	$client->styles($styles);
	
	my $string;
	if ($body->{'pod-type'} eq 'module') {
		$string = $client->pdf($body->{module}, 1);
	} elsif ($body->{'pod-type'} eq 'distribution') {
		$string = $client->dist_pdf($body->{distribution}, 1);
	} else {
		$string = $client->raw($body->{name}, $body->{raw}, 1);
	}

	return send_file(\$string, content_disposition => 'attachment', content_type => 'application/pdf', charset => 'utf-8');
};

our $generatePDF = compile_named(
	params => HashRef,
	name => StrMatch[ qr{([a-zA-Z0-9\-\:]+)} ],
	styles => Types::Standard::Optional->of(Str),
	size => Types::Standard::Optional->of(Enum[qw/A1 A2 A3 A4 A5 A6/]),
	template => Types::Standard::Optional->of(Str)
);

post '/generate/pdf' => sub {
	if ( not session('logged_in') ) {
        	send_error("Not logged in", 401);
    	}

	my $body = $generatePDF->(
		decode_json(request->body)
	);
	my @matches = $body->{template} =~ m/\{([^}]+)\}/xmsg;
	for my $match (@matches) {
		(my $param = $match) =~ s/\(.*\)//;
		$match = quotemeta($match);
		$body->{template} =~ s/\{$match\}/$body->{params}->{$param}/g;
	}

	my @lines = split "\n\n", $body->{template};

	my $file = Mxpress::PDF->new_pdf($body->{name}, decode_json($body->{styles}));

	$file->page->header->add(
		show_page_num => 'left',
		page_num_text => "page {num}",
		h => $file->mmp(10),
		padding => 5
	);

	$file->page->footer->add(
		show_page_num => 'right',
		page_num_text => "page {num}",
		h => $file->mmp(10),
		padding => 5
	);

	$file->title->add(
		'Table of Contents'
	)->toc->placeholder;

	my %map = (
		'=' => ['title', sub {
			$_[0]->toc->add(title => $_[1])
		}],
		'==' => ['subtitle', sub {
			$_[0]->toc->add(subtitle => $_[1])
		}],
		'===' => ['subsubtitle', sub {
			$_[0]->toc->add(subsubtitle => $_[1])
		}],
		'=t=' => ['input', sub {
			$_[0]->input->add($_[1])
		}],
		'=a=' => ['textarea', sub {
			my ($file, $line) = @_;
			my $lines = ($line =~ s/\((\d*)\)$// && $1);
			$file->textarea->add($line, lines => $lines);
		}],
		'=i=' => ['image', sub {
			$_[0]->image->add($_[1])
		}],
		'=l=' => ['line', sub {
			$_[0]->line->add
		}],
		'=s=' => ['select', sub {
			my ($file, $line) = @_;
			my @options = split ',', ($line =~ s/\((.*)\)$// && $1);
			$file->select->add($line);
		}],
	);

	my $reg = sprintf('^(%s)', join '|', map { quotemeta($_) } sort { length $b <=> length $a } keys %map);

	$map{text} = ['text', sub {
		$_[0]->text->add($_[1])
	}];

	for my $line (@lines) {
		$line =~ s/^\n//;
		$line =~ s/$reg//;
		my $plug = $1 || 'text';
		$line =~ m/()/;
		$line = join '', split("\n", $line);
		$map{$plug}[1]->($file, $line);
	}

	my $string = $file->stringify();
	
	return send_file(\$string, content_disposition => 'attachment', content_type => 'application/pdf', charset => 'utf-8' );
};

our $createTemplate = compile_named(
	name => StrMatch[ qr{([a-zA-Z0-9\-\:]+)} ],
	styles => Str,
	size => Enum[qw/A1 A2 A3 A4 A5 A6/],
	template => Str
);

post '/create/template' => sub {
	if ( not session('logged_in') ) {
        	send_error("Not logged in", 401);
    	}

	my $body = $createTemplate->(
		decode_json(request->body)
	);
	my $file = sprintf 'filedb/templates/%s-%s.txt', $body->{name}, $body->{size};
	open my $fh, '>', $file;
	print $fh $body->{template};
	close $fh;

	my %params;
	my @matches = $body->{template} =~ m/\{([^}]+)\}/xmsg;
	for my $match (@matches) {
		$match =~ s/\((.*)\)//;
		$params{$match} = $1 || ''; 
		$match =~ m/()/;
	}
	$body->{params} = \%params;


	$file = sprintf 'filedb/styles/%s-%s.txt', $body->{name}, $body->{size};
	open $fh, '>', $file;
	print $fh $body->{styles};
	close $fh;

	$body->{saved} = 1;

	return encode_json($body);
};

our $deleteTemplate = compile_named(
	name => StrMatch[ qr{([a-zA-Z0-9\-\:]+)} ],
	size => Enum[qw/A1 A2 A3 A4 A5 A6/],
);

post '/delete/template' => sub {
	if ( not session('logged_in') ) {
        	send_error("Not logged in", 401);
    	}
	my $body = $deleteTemplate->(
		decode_json(request->body)
	);
	my $file = sprintf "filedb/templates/%s-%s.txt", $body->{name}, $body->{size};
	unlink $file or die "cannot unlink file $file";

	my $style = sprintf "filedb/styles/%s-%s.txt", $body->{name}, $body->{size};
	unlink $style or die "cannot unlink file $file";

	return encode_json($body);
};

get '/templates' => sub {
	if ( not session('logged_in') ) {
        	send_error("Not logged in", 401);
    	}

	my $dir = 'filedb/templates';
	opendir my $dh, $dir or die "cannot opendir $dir";
	my @files = grep { !/^\./ } readdir $dh;
	close $dh;
	my @out;
	for my $f (@files) {
		open my $fh, '<', 'filedb/styles/' . $f or die "cannot open file $f";
		my $styles = do {local $/; <$fh> };
		close $fh;

		open $fh, '<', $dir . '/' . $f or die "cannot open file $f";
		my $content = do {local $/; <$fh> };
		close $fh;

		my %params;
		my @matches = $content =~ m/\{([^}]+)\}/xmsg;
		for my $match (@matches) {
			$match =~ s/\((.*)\)//;
			$params{$match} = $1 || ''; 
			$match =~ m/()/;
		}
		$f =~ s/filedb\/templates\///;
		$f =~ s/\.txt//;
		my ($name, $size) = split '-', $f;
		push @out, {
			name => $name,
			size => $size,
			template => $content,
			params => \%params,
			styles => $styles
		};
	}
	return encode_json(\@out);
};

true;

