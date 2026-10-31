use ExtUtils::MakeMaker;

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text lib/AnyEvent/MCP/Intro.pod | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "AnyEvent::MCP",
    LICENSE      => "perl_5",
    VERSION_FROM => "lib/AnyEvent/MCP.pm",
    EXE_FILES    => [
       "bin/anyevent-mcp",
       "bin/anyevent-mcp-askpermission",
       "bin/anyevent-mcp-form-elicitation",
       "bin/mcp-multibroker",
       "bin/mcp-fs",
       "bin/mcp-vim",
       "bin/mcp-webbrowser",
       "bin/mcp-ask-user",
       "bin/mcp-imap",
       "bin/mcp-http",
    ],
    PREREQ_PM    => {
       AnyEvent                    => 5.33,
       AnyEvent::HTTP              => 0,
       common::sense               => 3.3,
       parent                      => 0,
       JSON::XS                    => 3,
       Digest::SHA                 => 0,
       Scalar::Util                => 0,
       MIME::Base64                => 0,
       Encode                      => 0,
    },
    META_MERGE   => {
       'meta-spec' => { version => 2 },
       prereqs => {
          runtime => { recommends => {
             AnyEvent::WebSocket::Server  => 0,
             AnyEvent::WebSocket::Message => 0,
             AnyEvent::Fork::RPC          => 2.0,
             Mail::IMAPTalk               => 4.07,
             IO::Socket::SSL              => 0,
             Term::ReadKey                => 0,
          } },
          test => { recommends => {
             Protocol::WebSocket::Frame => 0,
          } },
       },
    },
    TEST_REQUIRES => {
       Test::More                 => 0.88,
       Pod::Checker               => 0,
    },
});

$mm->flush;

package MY;
sub test_via_harness {
   my ($self, $perl, $tests) = @_;

   # Keep errors visible, but not expected warnings or routine MCP activity.
   # An explicit PERL_ANYEVENT_LOG still takes precedence.
   # Use MakeMaker's built scripts, not installed programs or source shebangs.
   $self->SUPER::test_via_harness (
      'PATH="`pwd`/$(INST_SCRIPT):$$PATH" '
      . 'PERL_ANYEVENT_LOG="$${PERL_ANYEVENT_LOG:-filter=error log=error}" ' . $perl,
      $tests,
   )
}

package main;

sub MY::postamble {
   <<'MAKE'
dist: publish

publish: publish_vim_plugin publish_webbrowser_userscript

publish_vim_plugin:
	rsync -p --chmod=F644 vim/plugin/mcp-vim.vim dist.schmorp.de:/var/www/dist.schmorp.de/mcp-vim/1/.

publish_webbrowser_userscript:
	rsync -p --chmod=F644 webbrowser/mcp-webbrowser.user.js dist.schmorp.de:/var/www/dist.schmorp.de/mcp-webbrowser/1/.

MAKE
}

