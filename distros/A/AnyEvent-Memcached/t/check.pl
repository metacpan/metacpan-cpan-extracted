use common::sense;
runtest {
	my ($host,$port,%args) = @_;
	my $cv;$cv = AE::cv;
	diag "testing $host:$port";
	require Test::NoWarnings;Test::NoWarnings->import;
	plan tests => 52+1;

	my $memd = AnyEvent::Memcached->new(
		servers   => [ "$host:$port" ],
		cv        => $cv,
		debug     => 0,
		%args,
		namespace => "AE::Memd::t/$$/" . (time() % 100) . "/",
	);

	isa_ok($memd, 'AnyEvent::Memcached');
	$cv->begin;
	$memd->set('cas2','val2',cb => sub { ok(shift,"set cas2 as val1") or diag "  Error: @_"; });
	$memd->set('cas1','val1',cb => sub {
		ok(shift,"set cas as val1") or diag "  Error: @_";
		$memd->gets('cas1',cb => sub {
			my $value = shift;
			if ($value) {
			ok $value, 'got result' or diag "  Error: @_";
			is ref $value,'ARRAY', 'retval is array';
			is $value->[1], 'val1', 'value correct';
			# Now, break the value
			$memd->set('cas1','val2',cb => sub {
				ok(shift,"set cas as val2") or diag "  Error: @_";
				$memd->cas('cas1', $value->[0], 'val3',cb => sub {
					ok(!shift,"try cas as val3");
					ok(!@_, 'cas have no errors') or diag "  Error: @_";
					$memd->gets('cas1',cb => sub {
						ok my $value = shift, 'gets again';
						$memd->cas('cas1', $value->[0], 'val4',cb => sub {
							ok(shift,"set cas as val4");
							ok(!@_, 'cas have no errors') or diag "  Error: @_";
							
							#Now, test 2 keys at once
							$memd->gets(['cas1','cas2'], cb => sub {
								ok my $values = shift, 'got gets* result' or diag "  Error: @_";
								is ref $values, 'HASH', 'retval is hash';
								ok exists $values->{cas1}, 'have cas1';
								ok exists $values->{cas2}, 'have cas2';
								is ref $values->{cas1}, 'ARRAY', 'value 1 correct';
								is ref $values->{cas2}, 'ARRAY', 'value 2 correct';
								$memd->cas('cas1', $values->{cas1}[0], 'val5',cb => sub {
									ok(shift,"set cas1 as val5");
									ok(!@_, 'cas1 have no errors') or diag "  Error: @_";
								});
								$memd->cas('cas2', $values->{cas2}[0], 'val5',cb => sub {
									ok(shift,"set cas2 as val5");
									ok(!@_, 'cas2 have no errors') or diag "  Error: @_";
								});
								
							});
							
						});
					});
				});
				
			});
			} else {
				my $error = shift;
				SKIP: {
					if ($error =~ /not enabled/) {
						skip "gets not enabled",19;
					} else {
						fail "gets failed";
						diag "$error";
						skip "gets failed",18;
					}
				}
			}
		});
	});
	$memd->set("key1", "val1", cb => sub {
		ok(shift,"set key1 as val1") or diag "  Error: @_";
		$memd->get("key1", cb => sub {
			is(shift, "val1", "get key1 is val1") or diag "  Error: @_";
			$memd->add("key1", "val-replace", cb => sub {
				ok(! shift, "add key1 properly failed");
				$memd->add("key2", "val2", cb => sub {
					ok(shift, "add key2 as val2");
					$memd->get("key2", cb => sub {
						is(shift, "val2", "get key2 is val2") or diag "@_";
						$memd->replace("key2", "val-replace", cb => sub {
							ok(shift, "replace key2 as val-replace");
							$memd->get("key2", cb => sub {
								is(shift, "val-replace", "get key2 is val-replace") or diag "@_";
								$memd->set( key4 => {ref => 1}, cb => sub {
									ok shift, 'set ref' or diag "@_";
									$memd->get(
										[qw(key2 key4)],
										cb => sub {
											ok(my $r = shift, 'get multi');
											is_deeply $r,
												{ qw(key2 val-replace key4 ), {ref => 1} },
												'get multi values';
										},
									);
								});
								
								$memd->rget('1','0', cb => sub {
									my ($r,$e) = @_;
									
									if (!$e) {
										$memd->set("key3", "val3", cb => sub {
											ok(shift,"set key3 as val3");
											$memd->rget('key2','key3', cb => sub { # +left, +right
												my $r = shift;
												is( $r->{ 'key2' }, 'val-replace', 'rget[].key2' );
												is( $r->{ 'key3' }, 'val3', 'rget[].key3' );
											});
											$memd->rget('key2','key3', '+right' => 0, cb => sub {
												my $r = shift;
												is( $r->{ 'key2' }, 'val-replace', 'rget[).key2' );
												ok(! exists $r->{ 'key3' }, '!rget[).key3' );
											});
											$memd->rget('key2','key3', '+left' => 0, cb => sub {
												my $r = shift;
												ok(! exists $r->{ 'key2' }, '!rget(].key2' );
												is( $r->{ 'key3' }, 'val3', 'rget(].key3' );
											});
											
											$memd->rget('key2','key3', rv => 'array', cb => sub { # +left, +right
												my $r = shift;
												is_deeply $r,
													[qw(key2 val-replace key3 val3)],
													'rget[] array';
											});
											$memd->rget('key2','key3', '+right' => 0, rv => 'array', cb => sub {
												my $r = shift;
												is_deeply $r,
													[qw(key2 val-replace)],
													'rget[) array';
											});
											$memd->rget('key2','key3', '+left' => 0, rv => 'array', cb => sub {
												my $r = shift;
												is_deeply $r,
													[qw(key3 val3)],
													'rget(] array';
											});
										});
									} else {
										like( $e, qr/rget not supported/, 'rget fails' );
										SKIP: { skip "Have no rget",6+3 }
									}
								});
								
							});
						});
					});
				});
				$memd->delete("key1", cb => sub {
					ok(shift, "delete key1");
					$memd->get("key1", cb => sub {
						ok(! shift, "get key1 properly failed");
					});
					
				});
			});
		});
	});
	$memd->replace("key-noexist", "bogus", cb => sub {
		ok(!shift , "replace key-noexist properly failed");
	});
	my $need;
	$memd->set("ikey", $need = 3, cb => sub {
		ok(shift,"set ikey as 3") or diag "  Error: @_";
		#$memd->incr(ikey => 1, noreply => 1) and warn("norply ok"), ++$need;
		$memd->incr(ikey => 1, cb => sub {
			++$need;
			my $igot = shift;
			is $igot, $need, 'incr ikey = '.$igot or diag "  Error: @_";
			$need = $igot-2;
			#$memd->decr(ikey => 2, noreply => 1);# or $need -= 2;
			$memd->decr(ikey => 2, cb => sub {
				my $dgot = shift;
				is $dgot, $need, 'decr ikey = '.$dgot or diag "  Error: @_";
				$memd->get('ikey', cb => sub {
					diag "get after incr/decr = ".shift;
				});
			});
		});
	});
	$memd->incadd(iakey => 42, cb => sub {
		is $_[0],42, 'incadd works as add';
		$memd->get(iakey => cb => sub {
			is $_[0],42, 'incadd works as add (get check)';
			$memd->incadd(iakey => 42, cb => sub {
				is $_[0], 42*2, 'incadd works as inc';
				$memd->get(iakey => cb => sub {
					is $_[0],42*2, 'incadd works as inc (get check)';
				});
			});
		});
	});
	$cv->end;
	$cv->recv;
	$memd->destroy();

};
