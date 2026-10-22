use ExtUtils::MakeMaker;

my $mm = MM->new({
    dist         => {
       PREOP	=> 'pod2text lib/AnyEvent/MCP/Intro.pod | tee README >$(DISTVNAME)/README; chmod -R u=rwX,go=rX . ;',
       COMPRESS	=> 'gzip -9v',
       SUFFIX	=> '.gz',
	            },
    NAME         => "AnyEvent::MCP",
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
    ],
    PREREQ_PM    => {
       AnyEvent                    => 5.33,
       AnyEvent::HTTP              => 0,
       AnyEvent::WebSocket::Server  => 0,
       AnyEvent::WebSocket::Message => 0,
       common::sense               => 3.3,
       parent                      => 0,
       JSON::XS                    => 3,
       Digest::SHA                 => 0,
       Scalar::Util                => 0,
       MIME::Base64                => 0,
       Encode                      => 0,
    },
    TEST_REQUIRES => {
       Test::More                 => 0.88,
       Pod::Checker               => 0,
       Protocol::WebSocket::Frame => 0,
    },
});

$mm->flush;

package MY;
sub test_via_harness {
   my ($self, $perl, $tests) = @_;

   # Keep errors visible, but not expected warnings or routine MCP activity.
   # An explicit PERL_ANYEVENT_LOG still takes precedence.
   $self->SUPER::test_via_harness (
      'PERL_ANYEVENT_LOG="$${PERL_ANYEVENT_LOG:-filter=error log=error}" ' . $perl,
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

