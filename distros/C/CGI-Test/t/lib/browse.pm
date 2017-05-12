package browse;

use Config;
use Test::More;

use CGI::Test;

use constant WINDOWS => eval { $^O =~ /Win32|cygwin/ };

#
# This is a workaround for a nasty Fcntl loading problem: it seems that
# certain custom Perl builds fail to allocate some kind of resources, or
# just try to load wrong shared objects. This results in tests
# failing miserably; considering that custom builds are very common
# among CPAN testers, this could be considered a serious problem.
#
$ENV{PATH} = $Config{bin} . (WINDOWS ? ';' : ':') . $ENV{PATH};

sub browse {
    my %params = @_;

    my $method  = $params{method};
    my $enctype = $params{enctype};

    plan tests => 27;

	my $BASE = "http://server:18/cgi-bin";
    my $SCRIPT = WINDOWS ? 'getform.bat' : 'getform';
    my $ACTION = WINDOWS ? 'dumpargs.bat' : 'dumpargs';

	my $ct = CGI::Test->new(
		-base_url	=> $BASE,
		-cgi_dir	=> "t/cgi",
	);

	my $query = "action=/cgi-bin/$ACTION";
	$query .= "&method=$method" if defined $method;
	$query .= "&enctype=$enctype" if defined $enctype;

	my $page = $ct->GET("$BASE/$SCRIPT?$query");
	my $form = $page->forms->[0];

	is $form->action, "/cgi-bin/$ACTION", "Action: " . $form->action;

	my $submit = $form->submit_by_name("Send");

	ok defined $submit, "Send submit defined";

	my $page2 = $submit->press;

	ok $page2->is_ok, "Page 2 OK";

	my $args = parse_args($page2->raw_content);

	is  $args->{counter}, 1, "Page 2 counter";
	is  $args->{title}, "Mr", "Page 2 title";
	is  $args->{name}, "", "Page 2 name";
	is  $args->{skills}, "listening", "Page 2 skills";
	is  $args->{new}, "ON", "Page 2 new";
	is  $args->{color}, "white", "Page 2 color";
	is  $args->{note}, "", "Page 2 note";
	is  $args->{months}, "Jul", "Page 2 months";
	is  $args->{passwd}, "", "Page 2 passwd";
	is  $args->{Send}, "Send", "Page 2 send";
	is  $args->{portrait}, "", "Page 2 portrait";

	my $r = $form->radio_by_name("title");
	$r->check_tagged("Miss");

	my $m = $form->menu_by_name("months");
	$m->select("Jan");
	$m->select("Feb");
	$m->unselect("Jul");

	$m = $form->menu_by_name("color");
	$m->select("red");

	my $b = $form->checkbox_by_name("new");
	$b->uncheck;

	my $t = $form->input_by_name("portrait");
	$t->replace("this is ix");
	$t->append(", disappointed?");
	$t->filter(sub { s/\bix\b/it/ });

	$t = $form->input_by_name("passwd");
	$t->append("bar");
	$t->prepend("foo");

	$t = $form->input_by_name("note");
	$t->replace("this\nis\nsome\ntext");

	my $page3 = $submit->press;
	my $args3 = parse_args($page3->raw_content);

	is $args3->{counter}, 1, "Page 3 counter";
	is $args3->{title}, "Miss", "Page 3 title";
	is $args3->{name}, "", "Page 3 name";
	is $args3->{skills}, "listening", "Page 3 skills";
	ok !exists $args3->{new}, "Page 3 new";     # unchecked, not submitted
	is $args3->{color}, "red", "Page 3 color";
	is $args3->{note}, "this is some text", "Page 3 note";
	is join(" ", sort split(' ', $args3->{months})), "Feb Jan", "Page 3 months";
	is $args3->{passwd}, "foobar", "Page 3 passwd";
	is $args3->{Send}, "Send", "Page 3 send";
	is $args3->{portrait}, "this is it, disappointed?", "Page 3 portrait";

	# Ensure we tested what was requested
	$method = "GET" unless defined $method;
    my $enctype_qr = defined $enctype ? qr/multipart/ : qr/urlencoded/;

	is $form->method, $method, "Form method";
	like $form->enctype, $enctype_qr, "Form encoding";
}

# Rebuild parameter list from the output of dumpargs into a HASH
sub parse_args {
	my ($content) = @_;
	my %params;
	foreach my $line (split(/\r?\n/, $content)) {
		my ($name, $values) = split(/\t/, $line);
		$params{$name} = $values;
	}
	return \%params;
}

1;

