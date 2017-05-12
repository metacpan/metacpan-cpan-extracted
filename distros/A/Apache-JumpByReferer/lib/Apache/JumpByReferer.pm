package Apache::JumpByReferer;

use strict;
use Text::ParseWords;
use Apache::Constants qw(DECLINED REDIRECT FORBIDDEN OK);
use Apache::Log ();
use vars qw($VERSION);

$VERSION = '0.01';

my %LMOD;
my %DATA;

sub handler
{
	my $r = shift;

	return DECLINED unless $r->is_initial_req;

	my $referer = $r->header_in('Referer');
	return DECLINED unless defined $referer;

	return DECLINED unless (my $refl = read_reflist($r));

	my $redirect_to;

	foreach (keys %$refl) {
		if ($referer =~ /$_/) {
			$redirect_to = $refl->{$_};
			last;
		}
	}

	return DECLINED unless defined $redirect_to;

	return FORBIDDEN if uc($redirect_to) eq 'FORBIDDEN';

	if ($redirect_to =~ m{^https?://}) {
		$r->headers_out->set(Location => $redirect_to);
		return REDIRECT;
	} else {
		$r->internal_redirect($redirect_to);
		return OK;
	}
}

sub read_reflist
{
	my $r = shift;

	my $file = $r->dir_config('RefererListFile');
	my $flag = uc($r->dir_config('JumpByReferer'));

	$file =~ s/^(.+)\s*$/$1/; # removes space
	$flag =~ s/^(.+)\s*$/$1/; # removes space

	unless ($flag =~ /^O(?:N|FF)$/) {
		$r->server->log->warn(
			"\"PerlSetVar JumpByReferer\" directive must be On or Off"
		);
		return;
	}
	return unless $flag eq 'ON';
	unless (defined $file) {
		$r->server->log->alert(
			"\"PerlSetVar RefererListFile\" directive is not set"
		);
		return;
	}
	$file = $r->server_root_relative($file); 
	unless (-e $file) {
		$r->server->log->alert("$file: File does not exist");
		return;
	}

	my $mod = -M _;
	if ($LMOD{$file} && $LMOD{$file} <= $mod) {
		return $DATA{$file};
	}

	$LMOD{$file} = $mod;
	%{$DATA{$file}} = ();

	my $fh = Apache->gensym();
	unless (open($fh, $file)) {
		$r->server->log->alert("Cannot open $file: $!");
		return;
	}
	my $i = 0;
	while (<$fh>) {
		$i++;
		next if /^\s*#/ || /^\s*$/;
		chomp;
		if (/^\s*(.+)\s*$/) {
			my ($reg, $loc) = quotewords('\s+', 0, $1);
			if ($loc =~ /^\s*$/) {
				$r->server->log->info("$file line $i: parse error");
				next;
			}
			my $buf = $reg;
			$buf =~ s|(?<!\\)/|\\/|g;
			{ # testing the regular expressions
				local $@;
				eval '/' . $buf . '/';
				if ($@) {
					$r->server->log->alert(
						"$file line $i: \"$reg\" is invalid regexp"
					);
					next;
				}
			}
			$DATA{$file}->{$reg} = $loc;
		} else {
			$r->server->log->info(
				"$file line $i: parse error"
			);
		}
	}
	close $fh;
	$DATA{$file};
}

1;
__END__

=pod

=head1 NAME

Apache::JumpByReferer - Jump or block by Referer header field

=head1 SYNOPSIS

You need to compile mod_perl with PERL_ACCESS (or EVERYTHING) enabled.
And write the setting like below:

in httpd.conf

 <Directory /protected/directory/>
   PerlAccessHandler Apache::JumpByReferer
   PerlSetVar        RefererListFile conf/jump.conf
   PerlSetVar        JumpByReferer   On
 </Directory>

in RefererListFile (conf/jump.conf)

 # Syntax:
 # Referer Regex                       URL to Jump (or forbidden)

 http://malicious\.site\.example\.com/ http://goodbye.example.com/
 http://another\.malicious\.site/      forbidden
 http://ime\.nu/                       forbidden
 http://[^.]+\.google\.([^/]+)/        /hello_googler.html
 http://[^.]+\.yahoo\.([^/]+)/         /do_you_yahoo/?
 "Field blocked by"                    /do/not/block/the/field/

=head1 DESCRIPTION

Apache::JumpByReferer is an access phase handler of Apache + mod_perl.
You can block or let the user jump to another URL if the user was
coming from your specified web site.

This handler will cache the settings at the first time calling, and
check the last-modified time of the C<RefererListFile>, and will
re-cache the settings when the file was modified after the last cached
time. That is to say, you can always rewrite to change your settings.

Write a regular expressions (I<REGEX>) of your specified URL in the
C<RefererListFile>, and join a URL to jump behind the I<REGEX> in the
blank(s) if you want to let B<jump> the user.
Write and join C<Forbidden> (case insensitive) string behind the
I<REGEX> in the blank(s) if you don't want to access to the directory.

=head1 DIRECTIVES

=over 4

=item * PerlSetVar JumpByReferer ( On | Off )

C<JumpByReferer> is a switch to work of this handler. You must write
C<On> or C<Off> (case insensitive) value to this directive. It returns
DECLINED and will not work if the directive is not set to C<On>.

=item * PerlSetVar RefererListFile FILENAME

You must write your settings to C<RefererListFile>. The file must be
readable for the user and group of settings of Apache C<User> and
C<Group> directive.

=back

=head1 SYNTAX OF RefererListFile

You should write a valid I<REGEX> from line-head. The I<REGEX> will be
tested to check it is valid, and cached on this namespace with
timestamp of the modified time. But won't be cached if the I<REGEX> is
invalid.

and write the jumping URL or C<Forbidden> behind the I<REGEX>.

If you want to write a I<REGEX> which is including some space
character, you have to quote it. If you don't quote it, the parsing of
the text is failed.

This handler will do C<internal_redirect()> if the URL is internal
of own server. And this handler will print a C<Location> header with
C<REDIRECT> status if the URL is external. The judgement of it, an
external URL is started from C<http(s)://>, or an internal URI is
started from others.

The comment line is started by C<#> character, and it will be ignored
a blank line.

=head1 NOTES

This handler applies as for the initial request, namely does not work
for sub request and internal redirect. Because the server may be
fallen into endless loop if it applies for them.
Almost every non-initial requests are had same Referer header field as
initial request. This handler calls the internal redirect, and this
handler will redirect to current URI again and again when the handler
applies for non-initial request too and the directory setting of
redirection URI is inherited the parent settings. Because this case is
inside of the effective range of the B<JumpByReferer> setting. Perhaps
your system resources are run through in an instant by the handler
when the handler works for non-initial request too. Therefore this
function (does not work for non-initial request) exists for
self-defense. There is probably no problem in this setting. But,
understand these things fully when you use this module, please.

=head1 TODO

* I should know how to use Apache::test for testing this module.

* I should know whether it's the best way to put the handler under
  C<PerlAccessHandler>.

* Probably, I should study English more to write the document neatly.

=head1 SEE ALSO

mod_perl(1), Apache(3), L<Text::ParseWords>

=head1 AUTHOR

Koichi Taniguchi E<lt>taniguchi@users.sourceforge.jpE<gt>

=head1 COPYRIGHT

Copyright (c) 2003 Koichi Taniguchi. Japan. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
