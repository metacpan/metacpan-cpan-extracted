return
    ([cpandist => qr{^(Cairo-\d|Prima-Cairo-\d)}, # XXX base id or full dist name with author?
      sub {
	  my($self, $dist) = @_;
	  if ($dist->base_id =~ m{^(Cairo-\d|Prima-Cairo-\d)}) {
	      if ($^O eq 'freebsd') {
		  return { package => 'cairo' };
	      } elsif ($^O eq 'linux' && $self->{linuxdistro} =~ m{^(debian|ubuntu|linuxmint)$}) {
		  return { package => 'libcairo2-dev' };
	      }
	  }
      }],
    );
