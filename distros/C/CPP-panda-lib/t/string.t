use 5.012;
use warnings;
use lib 't/lib';
use PLTest 'full';

*get_allocs = *CPP::panda::lib::Test::String::get_allocs; # get_allocs flushes allocations counters
my @immortal;
my $char_size;

subtest 'string(char)' => \&test_string, "CPP::panda::lib::Test::String", 1, "CPP::panda::lib::Test::String2";

undef @immortal;
done_testing();

sub test_string {
    my $class  = shift;
    $char_size = shift;
    my $other_alloc_class = shift;
    my $max_sso_chars = $class->MAX_SSO_CHARS();
    my $buf_size      = $class->BUF_SIZE();
    my $ebuf_size     = $class->EBUF_SIZE();
    my $literal_src   = "hello world, this is a literal string";
    my $literal_str   = string($literal_src);
    my $npos          = $class->npos;
    
    subtest 'new empty' => sub {
        my $s = $class->new_empty();
        cmp_deeply([$s->length, $s->data, $s->capacity], [0, "", 0], "string ok");
        undef $s;
        check_allocs(0, "allocs ok");
    };
    
    subtest 'new literal' => sub {
        my $s = $class->new_literal();
        cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($literal_str), $literal_str, 0], "string ok");
        undef $s;
        check_allocs(0, "allocs ok");
    };
    
    subtest 'new sso' => sub {
        my $source = "this string is definitely longer than max sso chars";
        my $cur = "";
        
        my (@to_cmp, @expected);
        while (length($cur) <= $max_sso_chars) {
            my $exp = string($cur);
            my $s = $class->new_ptr($exp);
            push @to_cmp, [$s->length, $s->data, $s->capacity];
            push @expected, [length($cur), $exp, $max_sso_chars];
            die "should not happen" if length($source) == 1;
            $cur .= substr($source, 0, 1, '');
        }
        cmp_deeply(\@to_cmp, \@expected, "sso strings ok for 0-$max_sso_chars chars");
        check_allocs(0, "no allocs yet");
        
        my $exp = string($cur);
        my $s = $class->new_ptr($exp);
        cmp_deeply([$s->length, $s->data, $s->capacity], [length($cur), $exp, length($cur)], "sso exceeded string ok");
        my $allocated = $buf_size + length($cur);
        undef $s;
        check_allocs([1, $allocated], [1, $allocated], "sso exceeded allocs ok");
    };
    
    subtest 'new internal' => sub {
        my $exp = string("this string is definitely longer than max sso chars");
        my $s = $class->new_ptr($exp);
        cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "string ok");
        undef $s;
        my $allocated = $buf_size + str_len($exp);
        check_allocs([1, $allocated], [1, $allocated], "allocs ok");
    };
    
    subtest 'new external' => sub {
        my $exp = string("this string is definitely longer than max sso chars");
        my $s = $class->new_external($exp);
        cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "string ok");
        undef $s;
        check_allocs([1, $ebuf_size],[1, $ebuf_size],0,[1, str_len($exp)], "ext deallocated");
    };
    
    subtest 'new external custom buf' => sub {
        my $exp = string("this string is definitely longer than max sso chars");
        my $s = $class->new_external_custom_buf($exp);
        check_allocs(0, "allocs ok");
        cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "string ok");
        undef $s;
        check_allocs(0,0,0,[1, str_len($exp)],1, "ext deallocated");
    }; 
       
    subtest 'new fill' => sub {
        subtest 'sso' => sub {
            my $exp = string("a" x 2);
            my $s = $class->new_fill(2, string('a'));
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, $max_sso_chars], "string ok");
            undef $s;
            check_allocs(0, "allocs ok");
        };
        subtest 'internal' => sub {
            my $exp = string("B" x 50);
            my $s = $class->new_fill(50, string("B"));
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, 50], "string ok");
            undef $s;
            my $allocated = $buf_size + str_len($exp);
            check_allocs([1, $allocated], [1, $allocated], "allocs ok");
        };
    };
    
    subtest 'new capacity' => sub {
        subtest 'sso' => sub {
            my $s = $class->new_capacity(2);
            cmp_deeply([$s->length, $s->data, $s->capacity], [0, "", $max_sso_chars], "string ok");
            undef $s;
            check_allocs(0, "allocs ok");
        };
        subtest 'internal' => sub {
            my $s = $class->new_capacity(50);
            cmp_deeply([$s->length, $s->data, $s->capacity], [0, "", 50], "string ok");
            undef $s;
            my $allocated = $buf_size + 50;
            check_allocs([1, $allocated], [1, $allocated], "allocs ok");
        };
    };
    
    subtest 'new copy ctor' => sub {
        subtest 'from empty' => sub {
            my $src = $class->new_empty;
            my $s = $class->new_copy($src);
            cmp_deeply([$s->length, $s->data, $s->caps], [0, "", 0,0], "string ok");
            cmp_deeply([$src->length, $src->data, $src->caps], [0, "", 0,0], "source string ok");
            undef $s; undef $src;
            check_allocs(0, "allocs ok");
        };
        subtest 'from literal' => sub {
            my $src = $class->new_literal;
            my $s = $class->new_copy($src);
            cmp_deeply([$s->length, $s->data, $s->caps], [str_len($literal_str), $literal_str, 0,0], "string ok");
            cmp_deeply([$src->length, $src->data, $src->caps], [str_len($literal_str), $literal_str, 0,0], "source string ok");
            undef $s;
            check_allocs(0, "allocs ok");
        };
        subtest 'from sso' => sub {
            my $exp = string("bu");
            my $src = $class->new_ptr($exp);
            my $s = $class->new_copy($src);
            cmp_deeply([$s->length, $s->data, $s->caps], [str_len($exp), $exp, $max_sso_chars, $max_sso_chars], "string ok");
            cmp_deeply([$src->length, $src->data, $src->caps], [str_len($exp), $exp, $max_sso_chars, $max_sso_chars], "source string ok");
            undef $s;
            check_allocs(0, "allocs ok");
        };
        subtest 'from internal' => sub {
            my $exp = string('bu' x 50);
            my $src = $class->new_ptr($exp);
            my $s = $class->new_copy($src);
            cmp_deeply([$s->length, $s->data, $s->caps], [str_len($exp), $exp, 0, 100], "string ok");
            cmp_deeply([$src->length, $src->data, $src->caps], [str_len($exp), $exp, 0, 100], "source string ok");
            my $allocated = $buf_size + 100;
            check_allocs([1, $allocated], "alloc ok before");
            undef $src;
            check_allocs(0, "buf hold");
            undef $s;
            check_allocs(0, [1, $allocated], "buf dropped");
        };
        subtest 'from external' => sub {
            my $exp = string("c" x 50);
            my $src = $class->new_external($exp);
            my $s = $class->new_copy($src);
            cmp_deeply([$s->length, $s->data, $s->caps], [str_len($exp), $exp, 0, 50], "string ok");
            cmp_deeply([$src->length, $src->data, $src->caps], [str_len($exp), $exp, 0, 50], "source string ok");
            check_allocs([1, $ebuf_size], "ebuf allocated");
            undef $src;
            check_allocs(0, "buf hold");
            undef $s;
            check_allocs(0,[1, $ebuf_size],0,[1, str_len($exp)], "buf+ebuf dropped");
        };
    };
    
    subtest 'new move ctor' => sub {
        subtest 'from empty' => sub {
            my $source = $class->new_empty;
            my $s = $class->new_move($source);
            cmp_deeply([$s->length, $s->data, $s->capacity], [0, "", 0], "str ok");
            cmp_deeply([$source->length, $source->data, $source->capacity], [0, "", 0], "source ok");
            undef $s; undef $source;
            check_allocs(0, "allocs ok");
        };
        subtest 'from literal' => sub {
            my $source = $class->new_literal;
            my $s = $class->new_move($source);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($literal_str), $literal_str, 0], "str ok");
            cmp_deeply([$source->length, $source->data, $source->capacity], [0, "", 0], "source ok");
            undef $s; undef $source;
            check_allocs(0, "allocs ok");
        };
        subtest 'from sso' => sub {
            my $exp = string("bu");
            my $source = $class->new_ptr($exp);
            my $s = $class->new_move($source);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, $max_sso_chars], "str ok");
            cmp_deeply([$source->length, $source->data, $source->capacity], [0, "", 0], "source ok");
            undef $s; undef $source;
            check_allocs(0, "allocs ok");
        };
        subtest 'from internal' => sub {
            my $exp = string('bu' x 50);
            my $source = $class->new_ptr($exp);
            my $s = $class->new_move($source);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, 100], "str ok");
            cmp_deeply([$source->length, $source->data, $source->capacity], [0, "", 0], "source ok");
            undef $s; undef $source;
            my $allocated = $buf_size + 100;
            check_allocs([1, $allocated], [1, $allocated], "allocs ok");
        };
        subtest 'from external' => sub {
            my $exp = string("c" x 50);
            my $source = $class->new_external($exp);
            my $s = $class->new_move($source);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "str ok");
            cmp_deeply([$source->length, $source->data, $source->capacity], [0, "", 0], "source ok");
            undef $s; undef $source;
            check_allocs([1, $ebuf_size],[1, $ebuf_size],0,[1, str_len($exp)], "allocs ok");
        };
    };
    
    subtest 'new offset' => sub {
        subtest 'from literal' => sub {
            my $exp = string(substr($literal_src, 2, 25));
            my $source = $class->new_literal;
            my $s = $class->new_offset($source, 2, 25);
            cmp_deeply([$s->length, $s->data, $s->capacity], [25, $exp, 0], "str ok");
            undef $s; undef $source;
            check_allocs(0, "allocs ok");
        };
        subtest 'from sso' => sub {
            my $exp = string("bu");
            my $source = $class->new_ptr($exp);
            my $s = $class->new_offset($source, 1, 1);
            cmp_deeply([$s->length, $s->data, $s->capacity], [1, string("u"), $max_sso_chars-1], "str ok");
            undef $s; undef $source;
            check_allocs(0, "allocs ok");
        };
        subtest 'from internal' => sub {
            my $exp = string('bu' x 50);
            my $source = $class->new_ptr($exp);
            my $s = $class->new_offset($source, 9, 5);
            cmp_deeply([$s->length, $s->data, $s->caps], [5, string("ububu"), 0,100-9], "str ok");
            undef $s; undef $source;
            my $allocated = $buf_size + 100;
            check_allocs([1, $allocated], [1, $allocated], "allocs ok");
        };
        subtest 'from external' => sub {
            my $exp = string("c" x 50);
            my $source = $class->new_external($exp);
            my $s = $class->new_offset($source, 10, 30);
            cmp_deeply([$s->length, $s->data, $s->caps], [30, string('c' x 30), 0,str_len($exp)-10], "str ok");
            undef $s; undef $source;
            check_allocs([1, $ebuf_size],[1, $ebuf_size],0,[1, str_len($exp)], "allocs ok");
        };
        subtest 'out of bounds' => sub {
            my $exp = string("hello");
            my $source = $class->new_ptr($exp);
            subtest 'too big length acts as npos' => sub {
                my $s = $class->new_offset($source, 3, 10);
                cmp_deeply([$s->length, $s->data], [2, string("lo")], "str ok");
            };
            ok(!eval {$class->new_offset($source, 6, 10)}, "too big offset throws exception");
        };
    };
    
    subtest 'substr' => sub {
        my $source = $class->new_ptr(string("hello world"));
        my $s = $source->substr(0, 5);
        cmp_deeply([$s->length, $s->data], [5, string("hello")], "str ok");
        $s = $source->substr(6);
        cmp_deeply([$s->length, $s->data], [5, string("world")], "str ok");
        $s = $source->substr(4, 3);
        cmp_deeply([$s->length, $s->data], [3, string("o w")], "str ok");
    };
    get_allocs();
    
    my $assign_literal;
    subtest 'assign literal' => $assign_literal = sub {
        my $meth = shift;
        subtest 'from empty' => sub {
            my $s = $class->new_empty;
            $s->$meth;
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($literal_str), $literal_str, 0], "string ok");
            undef $s;
            check_allocs(0, "allocs ok");
        };
        subtest 'from literal' => sub {
            my $s = $class->new_literal;
            $s->$meth;
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($literal_str), $literal_str, 0], "string ok");
            undef $s;
            check_allocs(0, "allocs ok");
        };
        subtest 'from sso' => sub {
            my $exp = string("bu");
            my $s = $class->new_ptr($exp);
            $s->$meth;
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($literal_str), $literal_str, 0], "string ok");
            undef $s;
            check_allocs(0, "allocs ok");
        };
        subtest 'from internal' => sub {
            my $exp = string('a' x 50);
            my $s = $class->new_ptr($exp);
            $s->$meth;
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($literal_str), $literal_str, 0], "string ok");
            undef $s;
            check_allocs([1, $buf_size+50], [1, $buf_size+50], "allocs ok");
        };
        subtest 'from external' => sub {
            my $exp = string("c" x 50);
            my $s = $class->new_external($exp);
            check_allocs([1, $ebuf_size], "ebuf allocated");
            $s->$meth;
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($literal_str), $literal_str, 0], "string ok");
            check_allocs(0,[1, $ebuf_size],0,[1, str_len($exp)], "buf+ebuf dropped");
            undef $s;
            check_allocs(0, "allocs ok");
        };
    }, 'assign_literal';
    subtest 'operator assign literal' => $assign_literal, 'op_assign_literal';
    
    my $assign_ptr;
    subtest 'assign ptr' => $assign_ptr = sub {
        my $meth = shift;
        subtest 'from literal' => sub {
            my $exp = string('0' x 50);
            my $s = $class->new_literal;
            $s->$meth($exp);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "string ok");
            $s = $class->new_literal;
            check_allocs([1, $buf_size + str_len($exp)], [1, $buf_size + str_len($exp)], "allocs ok");
            $exp = string('rt');
            $s->$meth($exp, 0);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, $max_sso_chars], "sso ok");
            undef $s;
            check_allocs(0, "allocs ok");
        };
        subtest 'from sso' => sub {
            my $exp = string('1' x 50);
            my $s = $class->new_ptr(string('yt'));
            $s->$meth($exp, 0);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "string ok");
            $s = $class->new_ptr(string('yt'));
            check_allocs([1, $buf_size + str_len($exp)], [1, $buf_size + str_len($exp)], "allocs ok");
            $exp = string('rt');
            $s->$meth($exp);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, $max_sso_chars], "sso ok");
            undef $s;
            check_allocs(0, "allocs ok");
        };
        subtest 'from internal' => sub {
            my $exp = string('1' x 50);
            my $s = $class->new_ptr(string('2' x 50));
            get_allocs();
            $s->$meth($exp);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, 50], "string ok");
            check_allocs(0, "no allocs for sufficient capacity");
            $s->$meth(string("so"));
            cmp_deeply([$s->length, $s->data, $s->capacity], [2, string("so"), 50], "string ok, didnt become sso");
            check_allocs(0, "no allocs for sufficient capacity");
            $exp = string('3' x 60);
            $s->$meth($exp);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, 60], "string ok");
            check_allocs([1, $buf_size + 60], [1, $buf_size + 50], "extended storage");
            undef $s;
            check_allocs(0, [1, $buf_size + 60], "allocs ok");
        };
        subtest 'from external' => sub {
            my $exp = string('4' x 50);
            my $s = $class->new_external(string('5' x 50));
            get_allocs();
            $s->$meth($exp);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, 50], "string ok");
            check_allocs(0, "no allocs for sufficient capacity");
            $exp = string('bt');
            $s->$meth($exp);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, 50], "string ok, didnt become sso");
            $exp = string ('6' x 70);
            $s->$meth($exp);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, 70], "string ok");
            check_allocs([1, $buf_size + 70], [1, $ebuf_size], 0, [1, 50], "extended storage moving to internal");
            undef $s;
            check_allocs(0,[1,$buf_size+70], "allocs ok");
        };
        subtest 'from cow' => sub {
            my $exp = string('1' x 40);
            my $tmp = $class->new_ptr(string('2' x 50));
            my $s = $class->new_copy($tmp);
            get_allocs();
            $s->$meth($exp);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, 40], "string detached");
            check_allocs([1, $buf_size+40], "string detached");
            $s = $class->new_copy($tmp);
            get_allocs();
            $s->$meth(string('qw'));
            cmp_deeply([$s->length, $s->data, $s->capacity], [2, string('qw'), $max_sso_chars], "string detached to sso");
            
            $tmp = $class->new_external(string('2' x 50));
            $s = $class->new_copy($tmp);
            get_allocs();
            $s->$meth($exp);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, 40], "string detached");
            check_allocs([1, $buf_size+40], "string detached");
            $s = $class->new_copy($tmp);
            get_allocs();
            $s->$meth(string('qw'));
            cmp_deeply([$s->length, $s->data, $s->capacity], [2, string('qw'), $max_sso_chars], "string detached to sso");
            
            undef $tmp; undef $s;
            get_allocs();
        };
    }, 'assign_ptr';
    subtest 'operator assign ptr' => $assign_ptr, 'op_assign_ptr';
    
    subtest 'assign external' => sub {
        subtest 'from literal' => sub {
            my $exp = string('0' x 50);
            my $s = $class->new_literal;
            $s->assign_external($exp);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "string ok");
            check_allocs([1, $ebuf_size], "allocs ok");
            undef $s;
            check_allocs(0,[1, $ebuf_size],0,[1,50], "allocs ok");
        };
        subtest 'from sso' => sub {
            my $exp = string('1' x 50);
            my $s = $class->new_ptr(string('yt'));
            $s->assign_external($exp);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "string ok");
            undef $s;
            check_allocs([1, $ebuf_size],[1, $ebuf_size],0,[1,50], "allocs ok");
        };
        subtest 'from internal' => sub {
            my $exp = string('1' x 50);
            my $s = $class->new_ptr(string('2' x 50));
            get_allocs();
            $s->assign_external($exp);
            check_allocs([1, $ebuf_size],[1, $buf_size + 50], "allocs ok");
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "string ok");
            undef $s;
            check_allocs(0,[1,$ebuf_size],0,[1,50], "allocs ok");
        };
        subtest 'from external' => sub {
            my $exp = string('4' x 50);
            my $s = $class->new_external(string("abcd"));
            get_allocs();
            $s->assign_external($exp);
            # refcnt = 1, this case is optimized to reuse ExternalBuffer instead of dropping and creating a new one
            check_allocs(0,0,0,[1,4], "allocs ok");
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "string ok");
            undef $s;
            check_allocs(0,[1,$ebuf_size],0,[1,50], "allocs ok");
            
            # refcnt = 2
            $s = $class->new_external(string("abcd"));
            my $tmp = $class->new_copy($s);
            get_allocs();
            $s->assign_external($exp);
            check_allocs([1,$ebuf_size], "allocs ok");
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "string ok");
            undef $tmp;
            check_allocs(0,[1,$ebuf_size],0,[1,4], "allocs ok");
            undef $s;
            check_allocs(0,[1,$ebuf_size],0,[1,50], "allocs ok");
        };
        subtest 'with custom buf' => sub {
            my $exp = string('4' x 50);
            my $s = $class->new_external(string("abcd"));
            get_allocs();
            $s->assign_external_custom_buf($exp);
            check_allocs(0,[1,$ebuf_size],0,[1,4], "allocs ok");
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "string ok");
            undef $s;
            check_allocs(0,0,0,[1,50],1, "allocs ok");
        };
    };
    
    subtest 'assign fill' => sub {
        my $s = $class->new_empty;
        $s->assign_fill(2, string('a'));
        cmp_deeply([$s->length, $s->data, $s->capacity], [2, string("aa"), $max_sso_chars], "string ok");
        check_allocs(0, "allocs ok");
        $s = $class->new_ptr(string('a' x 50));
        get_allocs();
        $s->assign_fill(10, string('b'));
        cmp_deeply([$s->length, $s->data, $s->capacity], [10, string("bbbbbbbbbb"), 50], "string ok");
        check_allocs(0, "allocs ok");
    };
    get_allocs();
    
    subtest 'operator assign char' => sub {
        my $s = $class->new_empty;
        $s->op_assign_char(string("A"));
        cmp_deeply([$s->length, $s->data, $s->capacity], [1, string("A"), $max_sso_chars], "string ok");
        $s->op_assign_char(string("B"));
        cmp_deeply([$s->length, $s->data, $s->capacity], [1, string("B"), $max_sso_chars], "string ok");
    };
    get_allocs();
    
    my $assign_copy;
    subtest 'assign copy' => $assign_copy = sub {
        my $meth = shift;
        subtest 'literal<->literal' => sub {
            my $src = $class->new_literal;
            my $s = $class->new_empty;
            $s->$meth($src);
            cmp_deeply([$_->length, $_->data, $_->capacity], [str_len($literal_str), $literal_str, 0], "string ok") for $s, $src;
            undef $s;
            check_allocs(0, "allocs ok");
        };
        subtest 'sso<->sso' => sub {
            my $exp = string("bu");
            my $src = $class->new_ptr($exp);
            my $s = $class->new_ptr(string("du"));
            check_allocs(0, "allocs ok");
            $s->$meth($src);
            cmp_deeply([$_->length, $_->data, $_->capacity], [str_len($exp), $exp, $max_sso_chars], "string ok") for $s, $src;
            check_allocs(0, "allocs ok");
            undef $s; undef $src;
            check_allocs(0, "allocs ok");
        };
        subtest 'internal<->internal' => sub {
            my $exp = string('q' x 50);
            my $src = $class->new_ptr($exp);
            my $s = $class->new_ptr(string('d' x 30));
            get_allocs();
            $s->$meth($src);
            cmp_deeply([$_->length, $_->data, $_->caps], [str_len($exp), $exp, 0,str_len($exp)], "string ok") for $s, $src;
            check_allocs(0,[1, $buf_size+30], "allocs ok");
            undef $s;
            check_allocs(0, "allocs ok");
            undef $src;
            check_allocs(0,[1, $buf_size+50], "allocs ok");
        };
        subtest 'external<->external' => sub {
            my $exp = string('q' x 50);
            my $src = $class->new_external($exp);
            my $s = $class->new_external(string('d' x 30));
            get_allocs();
            $s->$meth($src);
            cmp_deeply([$_->length, $_->data, $_->caps], [str_len($exp), $exp, 0,str_len($exp)], "string ok") for $s, $src;
            check_allocs(0,[1,$ebuf_size],0,[1,30], "allocs ok");
            undef $s;
            check_allocs(0, "allocs ok");
            undef $src;
            check_allocs(0,[1,$ebuf_size],0,[1,50], "allocs ok");
        };
        subtest 'same object' => sub {
            my $exp = string('q' x 50);
            my $s = $class->new_ptr($exp);
            get_allocs();
            $s->$meth($s);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "string ok");
            check_allocs(0, "allocs ok");
            undef $s;
            check_allocs(0,[1,$buf_size+50], "allocs ok");
        };
    }, 'assign_copy';
    subtest 'operator assign copy' => $assign_copy, 'op_assign_copy';
    
    subtest 'assign offset' => sub {
        subtest 'internal<->internal' => sub {
            my $exp = string('q' x 50);
            my $src = $class->new_ptr($exp);
            my $s = $class->new_ptr(string('d' x 30));
            get_allocs();
            $s->assign_offset($src, 10, 30);
            cmp_deeply([$s->length, $s->data, $s->caps], [30, string('q' x 30), 0,40], "string ok");
            check_allocs(0,[1, $buf_size+30], "allocs ok");
            undef $s;
            check_allocs(0, "allocs ok");
            undef $src;
            check_allocs(0,[1, $buf_size+50], "allocs ok");
        };
        subtest 'same object' => sub {
            my $exp = string('x' x 50);
            my $s = $class->new_external($exp);
            get_allocs();
            $s->assign_offset($s, 10, 30);
            cmp_deeply([$s->length, $s->data, $s->capacity], [30, string('x' x 30), 40], "string ok");
            check_allocs(0, "allocs ok");
            undef $s;
            check_allocs(0,[1,$ebuf_size],0,[1,50], "allocs ok");
        };
    };
    
    my $assign_move;
    subtest 'assign move' => $assign_move = sub {
        my $meth = shift;
        subtest 'literal<->literal' => sub {
            my $src = $class->new_literal;
            my $s = $class->new_empty;
            $s->$meth($src);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($literal_str), $literal_str, 0], "string ok");
            cmp_deeply([$src->length, $src->data, $src->capacity], [0, "", 0], "source ok");
            undef $s;
            check_allocs(0, "allocs ok");
        };
        subtest 'sso<->sso' => sub {
            my $exp = string("bu");
            my $src = $class->new_ptr($exp);
            my $s = $class->new_ptr(string("du"));
            check_allocs(0, "allocs ok");
            $s->$meth($src);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, $max_sso_chars], "string ok");
            cmp_deeply([$src->length, $src->data, $src->capacity], [0, "", 0], "source ok");
            check_allocs(0, "allocs ok");
            undef $s; undef $src;
            check_allocs(0, "allocs ok");
        };
        subtest 'internal<->internal' => sub {
            my $exp = string('q' x 50);
            my $src = $class->new_ptr($exp);
            my $s = $class->new_ptr(string('d' x 30));
            get_allocs();
            $s->$meth($src);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "string ok");
            cmp_deeply([$src->length, $src->data, $src->capacity], [0, "", 0], "source ok");
            check_allocs(0,[1, $buf_size+30], "allocs ok");
            undef $s;
            check_allocs(0,[1, $buf_size+50], "allocs ok");
            undef $src;
            check_allocs(0, "allocs ok");
        };
        subtest 'external<->external' => sub {
            my $exp = string('q' x 50);
            my $src = $class->new_external($exp);
            my $s = $class->new_external(string('d' x 30));
            get_allocs();
            $s->$meth($src);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "string ok");
            cmp_deeply([$src->length, $src->data, $src->capacity], [0, "", 0], "source ok");
            check_allocs(0,[1,$ebuf_size],0,[1,30], "allocs ok");
            undef $s;
            check_allocs(0,[1,$ebuf_size],0,[1,50], "allocs ok");
            undef $src;
            check_allocs(0, "allocs ok");
        };
        subtest 'same object' => sub {
            my $exp = string('q' x 50);
            my $s = $class->new_ptr($exp);
            get_allocs();
            $s->$meth($s);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "string ok");
            check_allocs(0, "allocs ok");
            undef $s;
            check_allocs(0,[1,$buf_size+50], "allocs ok");
        };
    }, 'assign_move';
    subtest 'operator assign move' => $assign_move, 'op_assign_move';
    
    subtest 'offset' => sub {
        subtest 'from literal' => sub {
            my $exp = string(substr($literal_src, 2, 25));
            my $s = $class->new_literal;
            $s->offset(2, 25);
            cmp_deeply([$s->length, $s->data, $s->capacity], [25, $exp, 0], "str ok");
            undef $s;
            check_allocs(0, "allocs ok");
        };
        subtest 'from sso' => sub {
            my $exp = string("bu");
            my $s = $class->new_ptr($exp);
            $s->offset(1, 1);
            cmp_deeply([$s->length, $s->data, $s->capacity], [1, string("u"), $max_sso_chars-1], "str ok");
            undef $s;
            check_allocs(0, "allocs ok");
        };
        subtest 'from internal' => sub {
            my $exp = string('bu' x 50);
            my $s = $class->new_ptr($exp);
            $s->offset(9, 5);
            cmp_deeply([$s->length, $s->data, $s->capacity], [5, string("ububu"), 100-9], "str ok");
            undef $s;
            my $allocated = $buf_size + 100;
            check_allocs([1, $allocated], [1, $allocated], "allocs ok");
        };
        subtest 'from external' => sub {
            my $exp = string("c" x 50);
            my $s = $class->new_external($exp);
            $s->offset(10, 30);
            cmp_deeply([$s->length, $s->data, $s->capacity], [30, string('c' x 30), str_len($exp)-10], "str ok");
            undef $s;
            check_allocs([1, $ebuf_size],[1, $ebuf_size],0,[1, str_len($exp)], "allocs ok");
        };
        subtest 'out of bounds' => sub {
            my $exp = string("hello");
            my $s = $class->new_ptr($exp);
            subtest 'too big length acts as npos' => sub {
                $s->offset(3, 10);
                cmp_deeply([$s->length, $s->data], [2, string("lo")], "str ok");
            };
            ok(!eval {$s->offset(6, 10)}, "too big offset throws exception");
        };
    };
    
    subtest 'swap' => sub {
        subtest 'literal<->literal' => sub {
            my $s1 = $class->new_empty;
            my $s2 = $class->new_literal;
            $s1->swap($s2);
            cmp_deeply([$s1->length, $s1->data, $s1->capacity], [str_len($literal_str), $literal_str, 0], "s1 ok");
            cmp_deeply([$s2->length, $s2->data, $s2->capacity], [0, "", 0], "s2 ok");
            undef $s1; undef $s2;
            check_allocs(0, "allocs ok");
        };
        subtest 'literal<->sso' => sub {
            my $exp = string('eb');
            my $s1 = $class->new_literal;
            my $s2 = $class->new_ptr($exp);
            $class->stdswap($s1, $s2);
            cmp_deeply([$s1->length, $s1->data, $s1->capacity], [str_len($exp), $exp, $max_sso_chars], "s1 ok");
            cmp_deeply([$s2->length, $s2->data, $s2->capacity], [str_len($literal_str), $literal_str, 0], "s2 ok");
            undef $s1; undef $s2;
            check_allocs(0, "allocs ok");
        };
        subtest 'literal<->internal' => sub {
            my $exp = string('eb' x 50);
            my $s1 = $class->new_literal;
            my $s2 = $class->new_ptr($exp);
            $s1->swap($s2);
            cmp_deeply([$s1->length, $s1->data, $s1->capacity], [str_len($exp), $exp, str_len($exp)], "s1 ok");
            cmp_deeply([$s2->length, $s2->data, $s2->capacity], [str_len($literal_str), $literal_str, 0], "s2 ok");
            undef $s1; undef $s2;
            check_allocs([1, $buf_size + str_len($exp)], [1, $buf_size + str_len($exp)], "allocs ok");
        };
        subtest 'literal<->external' => sub {
            my $exp = string('eb' x 50);
            my $s1 = $class->new_literal;
            my $s2 = $class->new_external($exp);
            check_allocs([1, $ebuf_size], "allocs ok");
            $class->stdswap($s1, $s2);
            cmp_deeply([$s1->length, $s1->data, $s1->capacity], [str_len($exp), $exp, str_len($exp)], "s1 ok");
            cmp_deeply([$s2->length, $s2->data, $s2->capacity], [str_len($literal_str), $literal_str, 0], "s2 ok");
            undef $s1; undef $s2;
            check_allocs(0,[1, $ebuf_size],0,[1, str_len($exp)], "allocs ok");
        };
        subtest 'sso<->sso' => sub {
            my $exp1 = string('eb');
            my $exp2 = string('ta');
            my $s1 = $class->new_ptr($exp1);
            my $s2 = $class->new_ptr($exp2);
            $s1->swap($s2);
            cmp_deeply([$s1->length, $s1->data, $s1->capacity], [str_len($exp2), $exp2, $max_sso_chars], "s1 ok");
            cmp_deeply([$s2->length, $s2->data, $s2->capacity], [str_len($exp1), $exp1, $max_sso_chars], "s2 ok");
            undef $s1; undef $s2;
            check_allocs(0, "allocs ok");
        };
        subtest 'sso<->internal' => sub {
            my $exp1 = string('eb');
            my $exp2 = string('ta' x 50);
            my $s1 = $class->new_ptr($exp1);
            my $s2 = $class->new_ptr($exp2);
            $class->stdswap($s1, $s2);
            cmp_deeply([$s1->length, $s1->data, $s1->capacity], [str_len($exp2), $exp2, str_len($exp2)], "s1 ok");
            cmp_deeply([$s2->length, $s2->data, $s2->capacity], [str_len($exp1), $exp1, $max_sso_chars], "s2 ok");
            undef $s1; undef $s2;
            check_allocs([1, $buf_size + str_len($exp2)], [1, $buf_size + str_len($exp2)], "allocs ok");
        };
        subtest 'sso<->external' => sub {
            my $exp1 = string('eb');
            my $exp2 = string('ta' x 50);
            my $s1 = $class->new_ptr($exp1);
            my $s2 = $class->new_external($exp2);
            check_allocs([1, $ebuf_size], "allocs ok");
            $s1->swap($s2);
            cmp_deeply([$s1->length, $s1->data, $s1->capacity], [str_len($exp2), $exp2, str_len($exp2)], "s1 ok");
            cmp_deeply([$s2->length, $s2->data, $s2->capacity], [str_len($exp1), $exp1, $max_sso_chars], "s2 ok");
            undef $s1; undef $s2;
            check_allocs(0,[1, $ebuf_size],0,[1, str_len($exp2)], "allocs ok");
        };
        subtest 'internal<->internal' => sub {
            my $exp1 = string('eb' x 100);
            my $exp2 = string('ta' x 50);
            my $s1 = $class->new_ptr($exp1);
            my $s2 = $class->new_ptr($exp2);
            check_allocs([2, $buf_size*2 + str_len($exp1) + str_len($exp2)], "allocs ok");
            $class->stdswap($s1, $s2);
            check_allocs(0, "allocs ok");
            cmp_deeply([$s1->length, $s1->data, $s1->capacity], [str_len($exp2), $exp2, str_len($exp2)], "s1 ok");
            cmp_deeply([$s2->length, $s2->data, $s2->capacity], [str_len($exp1), $exp1, str_len($exp1)], "s2 ok");
            undef $s1; undef $s2;
            check_allocs(0, [2, $buf_size*2 + str_len($exp1) + str_len($exp2)], "allocs ok");
        };
        subtest 'internal<->external' => sub {
            my $exp1 = string('eb' x 100);
            my $exp2 = string('ta' x 50);
            my $s1 = $class->new_ptr($exp1);
            my $s2 = $class->new_external($exp2);
            check_allocs([2, $ebuf_size + $buf_size + str_len($exp1)], "allocs ok");
            $s1->swap($s2);
            cmp_deeply([$s1->length, $s1->data, $s1->capacity], [str_len($exp2), $exp2, str_len($exp2)], "s1 ok");
            cmp_deeply([$s2->length, $s2->data, $s2->capacity], [str_len($exp1), $exp1, str_len($exp1)], "s2 ok");
            undef $s1; undef $s2;
            check_allocs(0, [2, $ebuf_size + $buf_size + str_len($exp1)], 0, [1, str_len($exp2)], "allocs ok");
        };
        subtest 'external<->external' => sub {
            my $exp1 = string('eb' x 100);
            my $exp2 = string('ta' x 50);
            my $s1 = $class->new_external($exp1);
            my $s2 = $class->new_external($exp2);
            $class->stdswap($s1, $s2);
            cmp_deeply([$s1->length, $s1->data, $s1->capacity], [str_len($exp2), $exp2, str_len($exp2)], "s1 ok");
            cmp_deeply([$s2->length, $s2->data, $s2->capacity], [str_len($exp1), $exp1, str_len($exp1)], "s2 ok");
            undef $s1; undef $s2;
            check_allocs([2, 2*$ebuf_size], [2, 2*$ebuf_size], 0, [2, str_len($exp1) + str_len($exp2)], "allocs ok");
        };
    };
    
    subtest 'clear' => sub {
        subtest 'literal' => sub {
            my $s = $class->new_literal;
            $s->clear();
            cmp_deeply([$s->length, $s->data, $s->capacity], [0, "", 0], "str ok");
            undef $s;
            check_allocs(0, "allocs ok");
        };
        subtest 'sso' => sub {
            my $exp = string("bu");
            my $s = $class->new_ptr($exp);
            $s->clear();
            cmp_deeply([$s->length, $s->data, $s->capacity], [0, "", $max_sso_chars], "str ok");
            undef $s;
            check_allocs(0, "allocs ok");
        };
        subtest 'internal' => sub {
            my $exp = string('bu' x 50);
            my $s = $class->new_ptr($exp);
            get_allocs();
            $s->clear();
            check_allocs(0, "allocs ok");
            cmp_deeply([$s->length, $s->data, $s->capacity], [0, "", str_len($exp)], "str ok");
            undef $s;
            check_allocs(0, [1,$buf_size+100], "allocs ok");
        };
        subtest 'external' => sub {
            my $exp = string("c" x 50);
            my $s = $class->new_external($exp);
            get_allocs();
            $s->clear();
            check_allocs(0, "allocs ok");
            cmp_deeply([$s->length, $s->data, $s->capacity], [0, "", str_len($exp)], "str ok");
            undef $s;
            check_allocs(0,[1, $ebuf_size],0,[1, str_len($exp)], "allocs ok");
        };
    };
    
    subtest 'copy' => sub {
        my $s = $class->new_ptr(string("the password for my bank account is w74mnds320ft but i won't tell you the login)"));
        my $t = $s->copy(0);
        is($t, "", "zero ok");
        $t = $s->copy(10);
        is($t, string("the passwo"), "count ok");
        $t = $s->copy(20, 15);
        is($t, string("r my bank account is"), "offset ok");
        $t = $s->copy(20, 70);
        is($t, string("the login)"), "too much count ok");
        $t = $s->copy($class->npos, 60);
        is($t, string(" tell you the login)"), "count=npos ok");
        ok(!eval { $s->copy(10, 90) }, "too much offset");
    };
    get_allocs();
    
    subtest 'to_bool, empty' => sub {
        my $s = $class->new_empty;
        ok($s->empty, "empty false");
        ok(!$s->to_bool, "empty false");
        $s = $class->new_ptr("a");
        ok(!$s->empty, "non-empty");
        ok($s->to_bool, "non-empty true");
    };
    
    subtest 'use_count' => sub {
        my $s1 = $class->new_literal;
        my $s2 = $class->new_copy($s1);
        is($s1->use_count, 1, "literal ok");
        $s1 = $class->new_ptr(string("ab"));
        $s2 = $class->new_copy($s1);
        is($s1->use_count, 1, "sso ok");
        $s1 = $class->new_ptr(string("a" x 50));
        is($s1->use_count, 1, "internal single ok");
        $s2 = $class->new_copy($s1);
        is($s1->use_count, 2, "internal cow ok");
        $s1 = $class->new_external(string("b" x 50));
        is($s1->use_count, 1, "external single ok");
        $s2 = $class->new_copy($s1);
        is($s1->use_count, 2, "external cow ok");
    };
    get_allocs();
    
    subtest 'detach' => sub {
        subtest 'literal' => sub {
            my $s = $class->new_literal;
            $s->detach;
            check_allocs([1, $buf_size + str_len($literal_str)], "allocs ok");
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($literal_str), $literal_str, str_len($literal_str)], "str ok");
        };
        get_allocs();
        subtest 'sso' => sub {
            my $s = $class->new_ptr(string("ab"));
            $s->detach;
            check_allocs(0, "allocs ok");
            cmp_deeply([$s->length, $s->data, $s->capacity], [2, string("ab"), $max_sso_chars], "str ok");
        };
        subtest 'internal' => sub {
            my $exp = string("q" x 50);
            my $s = $class->new_ptr($exp);
            get_allocs();
            $s->detach;
            check_allocs(0, "no cow - noop");
            my $s2 = $class->new_copy($s);
            $s->detach;
            check_allocs([1, $buf_size + str_len($exp)], "cow - detached");
            cmp_deeply([$s->length, $s->data, $s->capacity, $s->use_count], [str_len($exp), $exp, str_len($exp), 1], "str ok");
        };
        get_allocs();
        subtest 'external' => sub {
            my $exp = string("q" x 50);
            my $s = $class->new_external($exp);
            get_allocs();
            $s->detach;
            check_allocs(0, "no cow - noop");
            my $s2 = $class->new_copy($s);
            $s->detach;
            check_allocs([1, $buf_size + str_len($exp)], "cow - detached");
            cmp_deeply([$s->length, $s->data, $s->capacity, $s->use_count], [str_len($exp), $exp, str_len($exp), 1], "str ok");
        };
        get_allocs();
    };
    
    subtest 'at/op[]/front/back' => sub {
        my $s = $class->new_ptr(string("0123456789" x 5));
        my $tmp = $class->new_copy($s);
        get_allocs();
        cmp_deeply([$s->front(), $s->at(1), $s->at(2), $s->op_at(3), $s->back()], [string('0'), string('1'), string('2'), string('3'), string('9')], "read ok");
        ok(!eval {$s->at(1000)}, "read out of bounds ok");
        is($s->use_count, 2, "not detached");
        $s->front(string("9"));
        $s->at(1, string("8"));
        $s->op_at(2, string("7"));
        $s->back(string("0"));
        is($s->copy(10), string("9873456789"), "changes occured");
        is($s->copy(5, 45), string("56780"), "changes occured");
        is($s->use_count, 1, "string detached");
    };
    get_allocs();
    
    subtest 'pop_back' => sub {
        my $s = $class->new_literal;
        my $exp = $class->new_literal->substr(0, str_len($literal_str)-1);
        $s->pop_back;
        cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($literal_str)-1, $exp->data, 0], "string ok");
        undef $s;
        check_allocs(0, "allocs ok");
    };
    
    subtest 'erase' => sub {
        subtest 'literal' => sub {
            my $s = $class->new_literal;
            $s->erase(11); # till end
            cmp_deeply([$s->length, $s->data, $s->capacity], [11, string("hello world"), 0], "str ok");
            check_allocs(0, "allocs ok");
            $s->erase(0, 6); # from beginning
            cmp_deeply([$s->length, $s->data, $s->capacity], [5, string("world"), 0], "str ok");
            check_allocs(0, "allocs ok");
            $s->erase(1, 3);
            cmp_deeply([$s->length, $s->data, $s->capacity], [2, string("wd"), $max_sso_chars], "str ok");
            check_allocs(0, "allocs ok");
        };
        get_allocs();
        subtest 'sso' => sub {
            return ok(1, "skipped for char size > 1") if $char_size > 1;
            my $s = $class->new_ptr(string("motherfuck"));
            $s->erase(8);
            cmp_deeply([$s->length, $s->data, $s->capacity], [8, string("motherfu"), $max_sso_chars], "str ok");
            $s->erase(0, 2);
            cmp_deeply([$s->length, $s->data, $s->capacity], [6, string("therfu"), $max_sso_chars-2], "str ok");
            $s->erase(1, 2);
            cmp_deeply([$s->length, $s->data, $s->capacity], [4, string("trfu"), $max_sso_chars-4], "str ok"); # head moved because it's shorter, so -2 to capacity
            undef $s;
            check_allocs(0, "allocs ok");
        };
        subtest 'internal' => sub {
            my $exp = string("0123456789" x 7);
            my $s = $class->new_ptr($exp);
            get_allocs();
            $s->erase(65);
            cmp_deeply([$s->length, $s->data, $s->capacity], [65, string("01234567890123456789012345678901234567890123456789012345678901234"), 70], "str ok");
            $s->erase(0, 5);
            cmp_deeply([$s->length, $s->data, $s->capacity], [60, string("567890123456789012345678901234567890123456789012345678901234"), 65], "str ok");
            $s->erase(5, 5);
            cmp_deeply([$s->length, $s->data, $s->capacity], [55, string("5678956789012345678901234567890123456789012345678901234"), 60], "str ok"); # head moved
            $s->erase(45, 5);
            cmp_deeply([$s->length, $s->data, $s->capacity], [50, string("56789567890123456789012345678901234567890123401234"), 60], "str ok"); # tail moved
            check_allocs(0, "allocs ok");
            my $s2 = $class->new_copy($s);
            cmp_deeply([$s2->length, $s2->data, $s2->caps], [50, string("56789567890123456789012345678901234567890123401234"), 0,60], "str2 ok");
            $s->erase(45);
            cmp_deeply([$s->length, $s->data, $s->caps], [45, string("567895678901234567890123456789012345678901234"), 0,60], "str ok");
            $s->erase(0, 5);
            cmp_deeply([$s->length, $s->data, $s->caps], [40, string("5678901234567890123456789012345678901234"), 0,55], "str ok");
            check_allocs(0, "allocs ok");
            is($s->use_count, 2, "cow mode");
            $s->erase(5, 5);
            cmp_deeply([$s->length, $s->data, $s->capacity], [35, string("56789567890123456789012345678901234"), 35], "str ok");
            is($s->use_count, 1, "detached");
            check_allocs([1, $buf_size+35], "allocs ok");
        };
        get_allocs();
        subtest 'external' => sub {
            my $exp = string("0123456789" x 5);
            my $s = $class->new_external($exp);
            get_allocs();
            $s->erase(45);
            cmp_deeply([$s->length, $s->data, $s->capacity], [45, string("012345678901234567890123456789012345678901234"), 50], "str ok");
            $s->erase(0, 5);
            cmp_deeply([$s->length, $s->data, $s->capacity], [40, string("5678901234567890123456789012345678901234"), 45], "str ok");
            $s->erase(5, 5);
            cmp_deeply([$s->length, $s->data, $s->capacity], [35, string("56789567890123456789012345678901234"), 40], "str ok"); # head moved
            $s->erase(25, 5);
            cmp_deeply([$s->length, $s->data, $s->capacity], [30, string("567895678901234567890123401234"), 40], "str ok"); # tail moved
            check_allocs(0, "allocs ok");
            my $s2 = $class->new_copy($s);
            cmp_deeply([$s2->length, $s2->data, $s2->caps], [30, string("567895678901234567890123401234"), 0,40], "str2 ok");
            $s->erase(25);
            cmp_deeply([$s->length, $s->data, $s->caps], [25, string("5678956789012345678901234"), 0,40], "str ok");
            $s->erase(0, 5);
            cmp_deeply([$s->length, $s->data, $s->caps], [20, string("56789012345678901234"), 0,35], "str ok");
            check_allocs(0, "allocs ok");
            is($s->use_count, 2, "cow mode");
            $s->erase(1, 18);
            cmp_deeply([$s->length, $s->data, $s->capacity], [2, string("54"), $max_sso_chars], "str ok");
            is($s->use_count, 1, "detached");
        };
        get_allocs();
        subtest 'offset exceed' => sub {
            my $s = $class->new_literal;
            ok(!eval{ $s->erase(100); }, "croaks");
        };
    };
    
    subtest 'compare' => sub {
        my $s1 = $class->new_ptr(string("keyword"));
        my $s2 = $class->new_ptr(string("abcword"));
        my $s3 = $class->new_ptr(string("keyword1"));
        my $s4 = $class->new_ptr(string("keyword"));
        my $s5 = $class->new_ptr(string("word"));
        get_allocs();
        
        cmp_ok($s1->compare(0, 7, $s2, 0, 7), '>', 0, "cmp ok");
        cmp_ok($s1->compare(0, 7, $s3, 0, 8), '<', 0, "cmp ok");
        cmp_ok($s1->compare(0, 7, $s4, 0, 7), '==', 0, "cmp ok");
        cmp_ok($s1->compare(0, 7, $s5, 0, 4), '<', 0, "cmp ok");
        cmp_ok($s1->compare(0, 7, $s3, 0, 7), '==', 0, "cmp ok");
        cmp_ok($s1->compare(3, 4, $s5, 0, 4), '==', 0, "cmp ok");
        cmp_ok($s1->compare(3, 4, $s2, 3, 4), '==', 0, "cmp ok");
        
        ok(!eval{ $s1->compare(8, 7, $s2, 0, 7) }, "offset exceeded");
        ok(!eval{ $s1->compare(0, 7, $s2, 8, 7) }, "offset exceeded");

        cmp_ok($s1->compare(0, 10, $s4, 0, 7), '==', 0, "len exceeded");
        cmp_ok($s1->compare(0, 10, $s4, 0, 11), '==', 0, "len exceeded");
        
        is($class->op_eq($s1, $s3), 0, "eq ok");
        is($class->op_eq($s1, $s4), 1, "eq ok");
        is($class->op_ne($s1, $s3), 1, "ne ok");
        is($class->op_ne($s1, $s4), 0, "ne ok");
        is($class->op_gt($s1, $s2), 1, "gt ok");
        is($class->op_gt($s1, $s3), 0, "gt ok");
        is($class->op_gt($s1, $s4), 0, "gt ok");
        is($class->op_gte($s1, $s2), 1, "gt ok");
        is($class->op_gte($s1, $s3), 0, "gt ok");
        is($class->op_gte($s1, $s4), 1, "gt ok");
        is($class->op_lt($s1, $s2), 0, "gt ok");
        is($class->op_lt($s1, $s3), 1, "gt ok");
        is($class->op_lt($s1, $s4), 0, "gt ok");
        is($class->op_lte($s1, $s2), 0, "gt ok");
        is($class->op_lte($s1, $s3), 1, "gt ok");
        is($class->op_lte($s1, $s4), 1, "gt ok");
        
        check_allocs(0, "allocs ok");
    };
    
    subtest 'find' => sub {
        my $s = $class->new_ptr(string("jopa noviy god"));
        is($s->find($class->new_ptr(string("o"))), 1);
        is($s->find($class->new_ptr(string("jopa"))), 0);
        is($s->find($class->new_ptr(string("noviy"))), 5);
        is($s->find($class->new_ptr(string("god"))), 11);
        is($s->find($class->new_ptr(string("o")), 2), 6);
        is($s->find($class->new_ptr(string("")), 0), 0);
        is($s->find($class->new_ptr(string("")), 13), 13);
        is($s->find($class->new_ptr(string("")), 14), 14);
        is($s->find($class->new_ptr(string("")), 15), $npos);
        is($s->find($class->new_ptr(string("o")), 14), $npos);
        is($s->find($class->new_ptr(string("god")), 11), 11);
        is($s->find($class->new_ptr(string("god")), 12), $npos);
    };
    get_allocs();
    
    subtest 'rfind' => sub {
        my $s = $class->new_ptr(string("jopa noviy god"));
        is($s->rfind($class->new_ptr(string("o"))), 12);
        is($s->rfind($class->new_ptr(string("o")), 99999), 12);
        is($s->rfind($class->new_ptr(string("jopa"))), 0);
        is($s->rfind($class->new_ptr(string("jopa")), 0), 0);
        is($s->rfind($class->new_ptr(string("noviy"))), 5);
        is($s->rfind($class->new_ptr(string("o")), 11), 6);
        is($s->rfind($class->new_ptr(string("")), 0), 0);
        is($s->rfind($class->new_ptr(string("")), 13), 13);
        is($s->rfind($class->new_ptr(string("")), 14), 14);
        is($s->rfind($class->new_ptr(string("")), 15), 14);
        is($s->rfind($class->new_ptr(string("o")), 0), $npos);
        is($s->rfind($class->new_ptr(string("god")), 11), 11);
        is($s->rfind($class->new_ptr(string("god")), 10), $npos);
    };
    get_allocs();
    
    subtest 'find_first_of' => sub {
        my $s = $class->new_ptr(string("jopa noviy god"));
        is($s->find_first_of($class->new_ptr(string("o"))), 1);
        is($s->find_first_of($class->new_ptr(string("o")), 2), 6);
        is($s->find_first_of($class->new_ptr(string("o")), 14), $npos);
        is($s->find_first_of($class->new_ptr(string("")), 0), $npos);
        is($s->find_first_of($class->new_ptr(string("")), 15), $npos);
        is($s->find_first_of($class->new_ptr(string("pnv"))), 2);
        is($s->find_first_of($class->new_ptr(string("pnv")), 3), 5);
        is($s->find_first_of($class->new_ptr(string("pnv")), 6), 7);
        is($s->find_first_of($class->new_ptr(string("pnv")), 8), $npos);
    };
    get_allocs();
    
    subtest 'find_first_not_of' => sub {
        my $s = $class->new_ptr(string("jopa noviy god"));
        is($s->find_first_not_of($class->new_ptr(string("o"))), 0);
        is($s->find_first_not_of($class->new_ptr(string("j"))), 1);
        is($s->find_first_not_of($class->new_ptr(string("o")), 1), 2);
        is($s->find_first_not_of($class->new_ptr(string("d")), 13), $npos);
        is($s->find_first_not_of($class->new_ptr(string("")), 0), 0);
        is($s->find_first_not_of($class->new_ptr(string("")), 15), $npos);
        is($s->find_first_not_of($class->new_ptr(string("jopa nviy"))), 11);
        is($s->find_first_not_of($class->new_ptr(string("og ")), 10), 13);
        is($s->find_first_not_of($class->new_ptr(string("ogd ")), 10), $npos);
    };
    get_allocs();
    
    subtest 'find_last_of' => sub {
        my $s = $class->new_ptr(string("jopa noviy god"));
        is($s->find_last_of($class->new_ptr(string("o"))), 12);
        is($s->find_last_of($class->new_ptr(string("o")), 9999), 12);
        is($s->find_last_of($class->new_ptr(string("o")), 10), 6);
        is($s->find_last_of($class->new_ptr(string("o")), 1), 1);
        is($s->find_last_of($class->new_ptr(string("o")), 0), $npos);
        is($s->find_last_of($class->new_ptr(string("")), 0), $npos);
        is($s->find_last_of($class->new_ptr(string("")), 15), $npos);
        is($s->find_last_of($class->new_ptr(string("pnv"))), 7);
        is($s->find_last_of($class->new_ptr(string("pnv")), 6), 5);
        is($s->find_last_of($class->new_ptr(string("pnv")), 4), 2);
        is($s->find_last_of($class->new_ptr(string("pnv")), 1), $npos);
    };
    get_allocs();
    
    subtest 'find_last_not_of' => sub {
        my $s = $class->new_ptr(string("jopa noviy god"));
        is($s->find_last_not_of($class->new_ptr(string("o"))), 13);
        is($s->find_last_not_of($class->new_ptr(string("d"))), 12);
        is($s->find_last_not_of($class->new_ptr(string("d")), 9999), 12);
        is($s->find_last_not_of($class->new_ptr(string("d")), 12), 12);
        is($s->find_last_not_of($class->new_ptr(string("o")), 12), 11);
        is($s->find_last_not_of($class->new_ptr(string("j")), 0), $npos);
        is($s->find_last_not_of($class->new_ptr(string("")), 0), 0);
        is($s->find_last_not_of($class->new_ptr(string("")), 13), 13);
        is($s->find_last_not_of($class->new_ptr(string("")), 14), 13);
        is($s->find_last_not_of($class->new_ptr(string("")), 15), 13);
        is($s->find_last_not_of($class->new_ptr(string("nviy god"))), 3);
        is($s->find_last_not_of($class->new_ptr(string("jpa ")), 4), 1);
        is($s->find_last_not_of($class->new_ptr(string("jopa ")), 4), $npos);
    };
    get_allocs();
    
    subtest 'reserve' => sub {
        subtest 'literal' => sub {
            subtest '>len' => sub {
                my $s = $class->new_literal;
                $s->reserve(100);
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($literal_str), $literal_str, 100], "str ok");
                check_allocs([1, $buf_size+100], "allocs ok");
            };
            get_allocs();
            subtest '<len' => sub {
                my $s = $class->new_literal;
                $s->reserve(str_len($literal_str) - 1);
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($literal_str), $literal_str, str_len($literal_str)], "str ok");
                check_allocs([1, $buf_size+str_len($literal_str)], "allocs ok");
            };
            get_allocs();
            subtest '=0' => sub {
                my $s = $class->new_literal;
                $s->reserve(0);
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($literal_str), $literal_str, str_len($literal_str)], "str ok");
                check_allocs([1, $buf_size+str_len($literal_str)], "allocs ok");
            };
            get_allocs();
        };
        subtest 'sso' => sub {
            return ok(1, "skipped for char size > 1") if $char_size > 1;
            my $exp = string("hello");
            subtest '<= max sso' => sub {
                my $s = $class->new_ptr($exp);
                $s->reserve(0);
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, $max_sso_chars], "str ok");
                check_allocs(0, "allocs ok");
                $s->reserve($max_sso_chars);
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, $max_sso_chars], "str ok");
                check_allocs(0, "allocs ok");
            };
            get_allocs();
            subtest '> max sso' => sub {
                my $s = $class->new_ptr($exp);
                $s->reserve($max_sso_chars+1);
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, $max_sso_chars+1], "str ok");
                check_allocs([1, $buf_size+$max_sso_chars+1], "allocs ok");
            };
            get_allocs();
            subtest 'offset, <= capacity' => sub {
                my $s = $class->new_ptr(string("hi").$exp);
                $s->offset(2);
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, $max_sso_chars-2], "str ok");
                $s->reserve($max_sso_chars-2);
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, $max_sso_chars-2], "str ok");
                check_allocs(0, "allocs ok");
            };
            subtest 'offset, > capacity, <= max sso' => sub {
                my $s = $class->new_ptr(string("hi").$exp);
                $s->offset(2);
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, $max_sso_chars-2], "str ok");
                $s->reserve($max_sso_chars);
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, $max_sso_chars], "str ok");
                check_allocs(0, "allocs ok"); # string should has been moved to the beginning, no allocs
            };
            get_allocs();
        };
        subtest 'internal' => sub {
            my $exp = string("abcde" x 10); 
            subtest 'detach cow' => sub {
                my $s = $class->new_ptr($exp);
                get_allocs();
                my $s2 = $class->new_copy($s);
                $s->reserve(str_len($exp)-1);
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "str ok");
                is($s->use_count, 1, "detached");
                check_allocs([1, $buf_size+str_len($exp)], "allocs ok");
                $s = $class->new_copy($s2);
                get_allocs();
                $s->offset(10, 30);
                my $tmp = $s->data;
                $s->reserve(0);
                cmp_deeply([$s->length, $s->data, $s->capacity], [30, $tmp, 30], "str ok");
                is($s->use_count, 1, "detached");
                check_allocs([1, $buf_size+30], "allocs ok - detached with minimum required capacity");
                $s = $class->new_copy($s2);
                get_allocs();
                $s->offset(10, 30);
                $s->reserve(100);
                cmp_deeply([$s->length, $s->data, $s->capacity], [30, $tmp, 100], "str ok");
                is($s->use_count, 1, "detached");
                check_allocs([1, $buf_size+100], "allocs ok");
            };
            get_allocs();
            subtest '<= max capacity' => sub {
                my $s = $class->new_ptr($exp);
                get_allocs();
                $s->reserve(0);
                $s->reserve(str_len($exp));
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "str ok");
                check_allocs(0, "allocs ok");
            };
            get_allocs();
            subtest '> max capacity' => sub {
                my $s = $class->new_ptr($exp);
                get_allocs();
                $s->reserve(80);
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, 80], "str ok");
                check_allocs(0,0,[1, 30], "reallocs ok");
            };
            get_allocs();
            subtest 'offset, <= capacity' => sub {
                my $s = $class->new_ptr($exp);
                get_allocs();
                $s->offset(10);
                my $data = $s->data;
                $s->reserve(40);
                cmp_deeply([$s->length, $s->data, $s->capacity], [40, $data, 40], "str ok");
                check_allocs(0, "allocs ok");
            };
            get_allocs();
            subtest 'offset, > capacity, <= max capacity' => sub {
                my $s = $class->new_ptr($exp);
                get_allocs();
                $s->offset(10);
                my $data = $s->data;
                $s->reserve(50);
                cmp_deeply([$s->length, $s->data, $s->capacity], [40, $data, 50], "str ok");
                check_allocs(0, "allocs ok"); # str has been moved to the beginning
            };
            get_allocs();
            subtest 'offset, > max capacity' => sub {
                my $s = $class->new_ptr($exp);
                get_allocs();
                $s->offset(20);
                my $data = $s->data;
                $s->reserve(70);
                cmp_deeply([$s->length, $s->data, $s->capacity], [30, $data, 70], "str ok");
                check_allocs([1, $buf_size+70],[1, $buf_size+50], "allocs ok");
            };
            get_allocs();
            subtest 'reserve to sso' => sub {
                my $s = $class->new_ptr($exp);
                my $s2 = $class->new_copy($s);
                get_allocs();
                $s->offset(0, 2);
                my $data = $s->data;
                $s->reserve(2);
                cmp_deeply([$s->length, $s->data, $s->capacity], [2, $data, $max_sso_chars], "str ok");
                check_allocs(0, "allocs ok");
            };
            get_allocs();
        };
        subtest 'external' => sub {
            my $exp = string("abcde" x 10); 
            subtest 'detach cow' => sub {
                my $s = $class->new_external($exp);
                get_allocs();
                my $s2 = $class->new_copy($s);
                $s->reserve(str_len($exp)-1);
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "str ok");
                is($s->use_count, 1, "detached");
                check_allocs([1, $buf_size+str_len($exp)], "allocs ok");
                $s = $class->new_copy($s2);
                get_allocs();
                $s->offset(10, 30);
                my $tmp = $s->data;
                $s->reserve(0);
                cmp_deeply([$s->length, $s->data, $s->capacity], [30, $tmp, 30], "str ok");
                is($s->use_count, 1, "detached");
                check_allocs([1, $buf_size+30], "allocs ok - detached with minimum required capacity");
                $s = $class->new_copy($s2);
                get_allocs();
                $s->offset(10, 30);
                $s->reserve(100);
                cmp_deeply([$s->length, $s->data, $s->capacity], [30, $tmp, 100], "str ok");
                is($s->use_count, 1, "detached");
                check_allocs([1, $buf_size+100], "allocs ok");
            };
            get_allocs();
            subtest '<= max capacity' => sub {
                my $s = $class->new_external($exp);
                get_allocs();
                $s->reserve(0);
                $s->reserve(str_len($exp));
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, str_len($exp)], "str ok");
                check_allocs(0, "allocs ok");
            };
            get_allocs();
            subtest '> max capacity' => sub {
                my $s = $class->new_external($exp);
                get_allocs();
                $s->reserve(80);
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp), $exp, 80], "str ok");
                check_allocs([1, $buf_size+80],[1, $ebuf_size],0,[1, str_len($exp)], "allocs ok");
            };
            get_allocs();
            subtest 'offset, <= capacity' => sub {
                my $s = $class->new_external($exp);
                get_allocs();
                $s->offset(10);
                my $data = $s->data;
                $s->reserve(40);
                cmp_deeply([$s->length, $s->data, $s->capacity], [40, $data, 40], "str ok");
                check_allocs(0, "allocs ok");
            };
            get_allocs();
            subtest 'offset, > capacity, <= max capacity' => sub {
                my $s = $class->new_external($exp);
                get_allocs();
                $s->offset(10);
                my $data = $s->data;
                $s->reserve(50);
                cmp_deeply([$s->length, $s->data, $s->capacity], [40, $data, 50], "str ok");
                check_allocs(0, "allocs ok"); # str has been moved to the beginning
            };
            get_allocs();
            subtest 'offset, > max capacity' => sub {
                my $s = $class->new_external($exp);
                get_allocs();
                $s->offset(20);
                my $data = $s->data;
                $s->reserve(70);
                cmp_deeply([$s->length, $s->data, $s->capacity], [30, $data, 70], "str ok");
                check_allocs([1, $buf_size+70],[1, $ebuf_size],0,[1, str_len($exp)], "allocs ok");
            };
            get_allocs();
            subtest 'reserve to sso' => sub {
                my $s = $class->new_external($exp);
                my $s2 = $class->new_copy($s);
                get_allocs();
                $s->offset(0, 2);
                my $data = $s->data;
                $s->reserve(2);
                cmp_deeply([$s->length, $s->data, $s->capacity], [2, $data, $max_sso_chars], "str ok");
                check_allocs(0, "allocs ok");
            };
            get_allocs();
        };
    };
    
    subtest 'resize' => sub {
        subtest 'literal' => sub {
            subtest 'less' => sub {
                my $s = $class->new_literal;
                $s->resize(1);
                cmp_deeply([$s->length, $s->capacity], [1, 0], "str ok");
                check_allocs(0, "allocs ok");
            };
            subtest 'more' => sub {
                my $s = $class->new_literal;
                $s->resize(str_len($literal_str) + 10);
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($literal_str) + 10, $literal_str.string("\0" x 10), str_len($literal_str) + 10], "str ok");
                check_allocs([1, $buf_size + str_len($literal_str) + 10], "allocs ok");
            };
            get_allocs();
        };
        subtest 'sso' => sub {
            return ok(1, "skipped for char size > 1") if $char_size > 1;
            my $exp = "world";
            subtest 'less' => sub {
                my $s = $class->new_ptr($exp);
                $s->resize(2);
                cmp_deeply([$s->length, $s->data, $s->capacity], [2, "wo", $max_sso_chars], "str ok");
                check_allocs(0, "allocs ok");
            };
            subtest 'more' => sub {
                my $s = $class->new_ptr($exp);
                $s->resize(7, "!");
                cmp_deeply([$s->length, $s->data, $s->capacity], [7, "world!!", $max_sso_chars], "str ok");
                check_allocs(0, "allocs ok");
            };
        };
        subtest 'internal' => sub {
            my $exp = string("a" x 50);
            subtest 'less' => sub {
                my $s = $class->new_ptr($exp);
                get_allocs();
                $s->resize(10);
                cmp_deeply([$s->length, $s->data, $s->capacity], [10, string("a" x 10), str_len($exp)], "str ok");
                check_allocs(0, "allocs ok");
            };
            get_allocs();
            subtest 'more' => sub {
                my $s = $class->new_ptr($exp);
                get_allocs();
                $s->resize(70, "b");
                cmp_deeply([$s->length, $s->data, $s->capacity], [70, string("a" x 50).string("b" x 20), 70], "str ok");
                check_allocs(0,0,[1,20], "reallocs ok");
            };
            get_allocs();
        };
        subtest 'external' => sub {
            my $exp = string("a" x 50);
            subtest 'less' => sub {
                my $s = $class->new_external($exp);
                get_allocs();
                $s->resize(10);
                cmp_deeply([$s->length, $s->data, $s->capacity], [10, string("a" x 10), str_len($exp)], "str ok");
                check_allocs(0, "allocs ok");
            };
            get_allocs();
            subtest 'more' => sub {
                my $s = $class->new_external($exp);
                get_allocs();
                $s->offset(40);
                $s->resize(20, "b");
                cmp_deeply([$s->length, $s->data, $s->capacity], [20, string("a" x 10).string("b" x 10), 50], "str ok");
                check_allocs(0, "allocs ok"); # because offset has been eliminated
            };
            get_allocs();
        };
    };
    
    subtest 'shrink_to_fit' => sub {
        subtest 'literal' => sub {
            my $s = $class->new_literal->substr(2, 5);
            $s->shrink_to_fit;
            is($s->capacity, 0, "noop");
            check_allocs(0, "allocs ok");
        };
        subtest 'sso' => sub {
            my $s = $class->new_ptr(string("ab"));
            $s->pop_back;
            $s->shrink_to_fit;
            is($s->capacity, $max_sso_chars, "noop");
            check_allocs(0, "allocs ok");
        };
        subtest 'internal owner' => sub {
            my $s = $class->new_ptr(string("a" x 50));
            get_allocs();
            $s->shrink_to_fit;
            cmp_deeply([$s->length, $s->data, $s->capacity], [50, string("a" x 50), 50], "noop");
            check_allocs(0, "no allocs");
            $s->offset(0, 40);
            $s->shrink_to_fit;
            cmp_deeply([$s->length, $s->data, $s->capacity], [40, string("a" x 40), 40], "shrinked");
            check_allocs(0,0,[1,-10], "realloced");
            $s->offset(10);
            $s->shrink_to_fit;
            cmp_deeply([$s->length, $s->data, $s->capacity], [30, string("a" x 30), 30], "shrinked");
            check_allocs([1,$buf_size+30],[1,$buf_size+40], "allocs ok");
            $s->offset(0,2);
            $s->shrink_to_fit;
            cmp_deeply([$s->length, $s->data, $s->capacity], [2, string("aa"), $max_sso_chars], "shrinked to sso");
            check_allocs(0,[1,$buf_size+30], "no allocs");
        };
        subtest 'internal cow' => sub {
            my $s = $class->new_ptr(string("a" x 50));
            my $tmp = $class->new_copy($s);
            get_allocs();
            $s->offset(10, 30);
            $s->shrink_to_fit;
            cmp_deeply([$s->length, $s->data, $s->caps], [30, string("a" x 30), 0,40], "noop");
            check_allocs(0, "no allocs");
            $s->offset(0, 2);
            $s->shrink_to_fit;
            cmp_deeply([$s->length, $s->data, $s->capacity], [2, string("aa"), $max_sso_chars], "shrinked to sso");
            check_allocs(0, "no allocs");
        };
        get_allocs();
        subtest 'external owner' => sub {
            my $s = $class->new_external(string("a" x 50));
            get_allocs();
            $s->shrink_to_fit;
            cmp_deeply([$s->length, $s->data, $s->capacity], [50, string("a" x 50), 50], "noop");
            check_allocs(0, "no allocs");
            $s->offset(0, 40);
            $s->shrink_to_fit;
            cmp_deeply([$s->length, $s->data, $s->capacity], [40, string("a" x 40), 40], "shrinked");
            check_allocs([1,$buf_size+40],[1,$ebuf_size],0,[1,50], "allocs ok - moved to internal");
            $s->offset(0,2);
            $s->shrink_to_fit;
            cmp_deeply([$s->length, $s->data, $s->capacity], [2, string("aa"), $max_sso_chars], "shrinked to sso");
            check_allocs(0,[1,$buf_size+40], "no allocs");
        };
        get_allocs();
        subtest 'external cow' => sub {
            my $s = $class->new_external(string("a" x 50));
            my $tmp = $class->new_copy($s);
            get_allocs();
            $s->offset(10, 30);
            $s->shrink_to_fit;
            cmp_deeply([$s->length, $s->data, $s->caps], [30, string("a" x 30), 0,40], "noop");
            check_allocs(0, "no allocs");
            $s->offset(0, 2);
            $s->shrink_to_fit;
            cmp_deeply([$s->length, $s->data, $s->capacity], [2, string("aa"), $max_sso_chars], "shrinked to sso");
            check_allocs(0, "no allocs");
        };
        get_allocs();
    };
    
    subtest 'append' => sub {
        subtest 'std' => sub {
            my $s = $class->new_ptr(string("abcd"));
            $s->append($class->new_ptr(string("1234")));
            cmp_deeply([$s->length, $s->data], [8, string("abcd1234")], "str ok");
            $s->append($class->new_ptr(string("qwerty")), 3);
            cmp_deeply([$s->length, $s->data], [11, string("abcd1234rty")], "str ok");
            $s->append($class->new_ptr(string("hello world")), 5, 4);
            cmp_deeply([$s->length, $s->data], [15, string("abcd1234rty wor")], "str ok");
            $s->append_chars(5, "x");
            cmp_deeply([$s->length, $s->data], [20, string("abcd1234rty worxxxxx")], "str ok");
            $s->append($s);
            cmp_deeply([$s->length, $s->data], [40, string("abcd1234rty worxxxxxabcd1234rty worxxxxx")], "append self ok");
        };
        subtest 'preserve_allocated_when_empty_but_reserved' => sub {
            my $s = $class->new_empty;
            my $s2 = $class->new_ptr(string("a" x 50));
            my $s3 = $class->new_ptr(string("b" x 10));
            get_allocs();
            $s->reserve(100);
            check_allocs([1, $buf_size+100], "allocs ok");
            $s->append($s2);
            check_allocs(0, "no allocs ok");
            $s->append($s3);
            check_allocs(0, "no allocs ok");
            cmp_deeply([$s->length, $s->data, $s->capacity], [60, string("a"x50).string("b"x10), 100], "str ok");
        };
        subtest 'use_cow_when_empty_without_reserve' => sub {
            my $s = $class->new_empty;
            my $s2 = $class->new_ptr(string("a" x 50));
            my $s3 = $class->new_ptr(string("b" x 10));
            get_allocs();
            $s->append($s2);
            check_allocs(0, "no allocs ok");
            $s->append($s3);
            check_allocs([1, $buf_size+60], "allocs ok");
            cmp_deeply([$s->length, $s->data, $s->capacity], [60, string("a"x50).string("b"x10), 60], "str ok");
        };
    };
    
    subtest 'op_plus' => sub {
        subtest 'str-str' => sub {
            my $lhs = $class->new_ptr(string("x" x 30));
            my $rhs = $class->new_ptr(string("y" x 40));
            get_allocs();
            my $s = $class->op_plus_ss($lhs, $rhs);
            cmp_deeply([$s->length, $s->data, $s->capacity], [70, string("x" x 30).string("y" x 40), 70], "str ok");
            cmp_deeply([map {$_->use_count} $lhs, $rhs, $s], [1, 1, 1], "no cows");
            check_allocs([1, $buf_size+70], "allocs ok");
            undef $s;
            get_allocs();
            $s = $class->op_plus_ss($lhs, $class->new_empty);
            cmp_deeply([$s->length, $s->data, $s->capacity], [$lhs->length, $lhs->data, 0], "str ok");
            cmp_deeply([map {$_->use_count} $lhs, $s], [2, 2], "cow");
            check_allocs(0, "allocs ok");
            undef $s;
            $s = $class->op_plus_ss($class->new_empty, $rhs);
            cmp_deeply([$s->length, $s->data, $s->capacity], [$rhs->length, $rhs->data, 0], "str ok");
            cmp_deeply([map {$_->use_count} $rhs, $s], [2, 2], "cow");
            check_allocs(0, "allocs ok");
        };
        get_allocs();
        subtest 'ptr-str' => sub {
            my $lhs = string("x" x 30);
            my $rhs = $class->new_ptr(string("y" x 40));
            get_allocs();
            my $s = $class->op_plus_ps($lhs, $rhs);
            cmp_deeply([$s->length, $s->data, $s->capacity], [70, string("x" x 30).string("y" x 40), 70], "str ok");
            cmp_deeply([map {$_->use_count} $rhs, $s], [1, 1], "no cows");
            check_allocs([1, $buf_size+70], "allocs ok");
            undef $s;
            get_allocs();
            $s = $class->op_plus_ps($lhs, $class->new_empty);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($lhs), $lhs, str_len($lhs)], "str ok");
            is($s->use_count, 1, "no cow");
            undef $s;
            get_allocs();
            $s = $class->op_plus_ps("", $rhs);
            cmp_deeply([$s->length, $s->data, $s->capacity], [$rhs->length, $rhs->data, 0], "str ok");
            cmp_deeply([map {$_->use_count} $rhs, $s], [2, 2], "cow");
            check_allocs(0, "allocs ok");
        };
        subtest 'char-str' => sub {
            my $lhs = string("x");
            my $rhs = $class->new_ptr(string("y" x 40));
            get_allocs();
            my $s = $class->op_plus_cs($lhs, $rhs);
            cmp_deeply([$s->length, $s->data, $s->capacity], [41, string("x").string("y" x 40), 41], "str ok");
            cmp_deeply([map {$_->use_count} $rhs, $s], [1, 1], "no cows");
            check_allocs([1, $buf_size+41], "allocs ok");
            undef $s;
            get_allocs();
            $s = $class->op_plus_cs($lhs, $class->new_empty);
            cmp_deeply([$s->length, $s->data, $s->capacity], [1, string("x"), $max_sso_chars], "str ok");
            check_allocs(0, "allocs ok");
        };
        get_allocs();
        subtest 'str-ptr' => sub {
            my $lhs = $class->new_ptr(string("y" x 40));
            my $rhs = string("x" x 30);
            get_allocs();
            my $s = $class->op_plus_sp($lhs, $rhs);
            cmp_deeply([$s->length, $s->data, $s->capacity], [70, string("y" x 40).string("x" x 30), 70], "str ok");
            cmp_deeply([map {$_->use_count} $lhs, $s], [1, 1], "no cows");
            check_allocs([1, $buf_size+70], "allocs ok");
            undef $s;
            get_allocs();
            $s = $class->op_plus_sp($class->new_empty, $rhs);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($rhs), $rhs, str_len($rhs)], "str ok");
            is($s->use_count, 1, "no cow");
            undef $s;
            get_allocs();
            $s = $class->op_plus_sp($lhs, "");
            cmp_deeply([$s->length, $s->data, $s->capacity], [$lhs->length, $lhs->data, 0], "str ok");
            cmp_deeply([map {$_->use_count} $lhs, $s], [2, 2], "cow");
            check_allocs(0, "allocs ok");
        };
        get_allocs();
        subtest 'str-char' => sub {
            my $lhs = $class->new_ptr(string("y" x 40));
            my $rhs = string("x");
            get_allocs();
            my $s = $class->op_plus_sc($lhs, $rhs);
            cmp_deeply([$s->length, $s->data, $s->capacity], [41, string("y" x 40).string("x"), 41], "str ok");
            cmp_deeply([map {$_->use_count} $lhs, $s], [1, 1], "no cows");
            check_allocs([1, $buf_size+41], "allocs ok");
            undef $s;
            get_allocs();
            $s = $class->op_plus_sc($class->new_empty, $rhs);
            cmp_deeply([$s->length, $s->data, $s->capacity], [1, string("x"), $max_sso_chars], "str ok");
            check_allocs(0, "allocs ok");
        };
        get_allocs();
        subtest 'mstr-str' => sub {
            my $lhs = $class->new_ptr(string("x" x 30));
            my $rhs = $class->new_ptr(string("y" x 20));
            $lhs->length(5);
            get_allocs();
            my $s = $class->op_plus_mss($lhs, $rhs);
            cmp_deeply([$s->length, $s->data, $s->capacity], [25, string("x" x 5).string("y" x 20), 30], "str ok");
            cmp_deeply([map {$_->use_count} $lhs, $rhs, $s], [1, 1, 1], "no cows");
            cmp_deeply($lhs->length, 0, "lhs moved");
            cmp_deeply($rhs->length, 20, "rhs ok");
            check_allocs(0, "allocs ok");
        };
        get_allocs();
        subtest 'str-mstr' => sub {
            my $lhs = $class->new_ptr(string("x" x 20));
            my $rhs = $class->new_ptr(string("y" x 30));
            $rhs->length(5);
            get_allocs();
            my $s = $class->op_plus_sms($lhs, $rhs);
            cmp_deeply([$s->length, $s->data, $s->capacity], [25, string("x" x 20).string("y" x 5), 30], "str ok");
            cmp_deeply([map {$_->use_count} $lhs, $rhs, $s], [1, 1, 1], "no cows");
            cmp_deeply($lhs->length, 20, "lhs ok");
            cmp_deeply($rhs->length, 0, "rhs moved");
            check_allocs(0, "allocs ok");
        };
        get_allocs();
        subtest 'mstr-mstr' => sub { # for now it's just lhs.append(rhs), i.e. the same as mstr-str
            my $lhs = $class->new_ptr(string("x" x 30));
            my $rhs = $class->new_ptr(string("y" x 20));
            $lhs->length(5);
            get_allocs();
            my $s = $class->op_plus_msms($lhs, $rhs);
            cmp_deeply([$s->length, $s->data, $s->capacity], [25, string("x" x 5).string("y" x 20), 30], "str ok");
            cmp_deeply([map {$_->use_count} $lhs, $rhs, $s], [1, 1, 1], "no cows");
            cmp_deeply($lhs->length, 0, "lhs moved");
            cmp_deeply($rhs->length, 20, "rhs ok");
            check_allocs(0, "allocs ok");
        };
        get_allocs();
        subtest 'ptr-mstr' => sub {
            my $lhs = string("x" x 30);
            my $rhs = $class->new_ptr(string("y" x 40));
            get_allocs();
            $rhs->length(5);
            my $s = $class->op_plus_pms($lhs, $rhs);
            cmp_deeply([$s->length, $s->data, $s->capacity], [35, string("x" x 30).string("y" x 5), 40], "str ok");
            cmp_deeply([map {$_->use_count} $rhs, $s], [1, 1], "no cows");
            cmp_deeply($rhs->length, 0, "rhs moved");
            check_allocs(0, "allocs ok");
        };
        get_allocs();
        subtest 'char-mstr' => sub {
            my $lhs = string("x");
            my $rhs = $class->new_ptr(string("y" x 40));
            get_allocs();
            $rhs->length(30);
            my $s = $class->op_plus_cms($lhs, $rhs);
            cmp_deeply([$s->length, $s->data, $s->capacity], [31, string("x").string("y" x 30), 40], "str ok");
            cmp_deeply([map {$_->use_count} $rhs, $s], [1, 1], "no cows");
            cmp_deeply($rhs->length, 0, "rhs moved");
            check_allocs(0, "allocs ok");
        };
        get_allocs();
        subtest 'mstr-ptr' => sub {
            my $lhs = $class->new_ptr(string("y" x 40));
            my $rhs = string("x" x 20);
            get_allocs();
            $lhs->length(20);
            my $s = $class->op_plus_msp($lhs, $rhs);
            cmp_deeply([$s->length, $s->data, $s->capacity], [40, string("y" x 20).string("x" x 20), 40], "str ok");
            cmp_deeply([map {$_->use_count} $lhs, $s], [1, 1], "no cows");
            cmp_deeply($lhs->length, 0, "lhs moved");
            check_allocs(0, "allocs ok");
        };
        get_allocs();
        subtest 'mstr-char' => sub {
            my $lhs = $class->new_ptr(string("y" x 40));
            my $rhs = string("x");
            get_allocs();
            $lhs->length(20);
            my $s = $class->op_plus_msc($lhs, $rhs);
            cmp_deeply([$s->length, $s->data, $s->capacity], [21, string("y" x 20).string("x"), 40], "str ok");
            cmp_deeply([map {$_->use_count} $lhs, $s], [1, 1], "no cows");
            cmp_deeply($lhs->length, 0, "lhs moved");
            check_allocs(0, "allocs ok");
        };
        get_allocs();
    };
    get_allocs();
    
    subtest 'insert' => sub {
        
        subtest 'literal' => sub {
            subtest 'end' => sub {
                my $exp = string(" hello");
                my $s = $class->new_literal;
                $s->insert($s->length, $exp);
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($literal_str.$exp), $literal_str.$exp, str_len($literal_str.$exp)], "str ok");
                check_allocs([1,$buf_size+str_len($literal_str.$exp)], "allocs ok");
            };
            get_allocs();
            subtest 'begin' => sub {
                my $exp = string("hello ");
                my $s = $class->new_literal;
                $s->insert(0, $exp);
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($exp.$literal_str), $exp.$literal_str, str_len($exp.$literal_str)], "str ok");
                check_allocs([1,$buf_size+str_len($exp.$literal_str)], "allocs ok");
            };
            get_allocs();
            subtest 'middle' => sub {
                my $exp = string("epta");
                my $s = $class->new_literal;
                $s->insert(5, $exp);
                my $tmp = $literal_src;
                substr($tmp, 5, 0, "epta");
                $tmp = string($tmp);
                cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($tmp), $tmp, str_len($tmp)], "str ok");
                check_allocs([1,$buf_size+str_len($tmp)], "allocs ok");
            };
            get_allocs();
        };

        my $test = sub {
            my $meth = shift;
            my $len  = shift;
            my $exp  = string("a" x $len);
            subtest 'end' => sub {
                subtest 'has end space' => sub {
                    my $s = $class->$meth($exp);
                    get_allocs();
                    $s->length($s->length - 6);
                    $s->insert($s->length, string(" world"));
                    cmp_deeply([$s->length, $s->data, $s->capacity], [$len, string(("a"x($len-6))." world"), $len], "str ok");
                    check_allocs(0, "allocs ok");
                };
                subtest 'has head space' => sub {
                    my $s = $class->$meth($exp);
                    get_allocs();
                    $s->offset($len - 3);
                    $s->insert($s->length, " world");
                    cmp_deeply([$s->length, $s->data, $s->capacity], [9, string("aaa world"), $len], "str ok"); # moved to the beginning
                    check_allocs(0, "allocs ok");
                };
                subtest 'has both space' => sub {
                    my $s = $class->$meth($exp);
                    get_allocs();
                    $s->offset(8, 5);
                    die "should not happen" if $s->capacity < 7;
                    $s->insert($s->length, " world");
                    cmp_deeply([$s->length, $s->data, $s->capacity], [11, string("aaaaa world"), $len-8], "str ok");
                    check_allocs(0, "allocs ok");
                };
                subtest 'has summary space' => sub {
                    my $s = $class->$meth($exp);
                    get_allocs();
                    $s->offset(4, $len-8); # 4 free from head and tail
                    $s->insert($s->length, "world"); # 5 insterted
                    cmp_deeply([$s->length, $s->data, $s->capacity], [$len-3, string(("a" x ($len-8))."world"), $len], "str ok"); # moved to the beginning
                    check_allocs(0, "allocs ok");
                };
                subtest 'has no space' => sub {
                    my $s = $class->$meth($exp);
                    get_allocs();
                    $s->offset(2, $len-4); # 2 free from head and tail
                    $s->insert($s->length, "world"); # 5 insterted
                    cmp_deeply([$s->length, $s->data, $s->capacity], [$len+1, string(("a" x ($len-4))."world"), $len+1], "str ok"); # moved to the beginning
                    check_allocs([1,$buf_size+$len+1], ignore(), ignore(), ignore(), "allocs ok");
                };
            };
            subtest 'begin' => sub {
                subtest 'has end space' => sub {
                    my $s = $class->$meth($exp);
                    get_allocs();
                    $s->length($s->length - 6);
                    $s->insert(0, string("world "));
                    cmp_deeply([$s->length, $s->data, $s->capacity], [$len, string("world ".("a"x($len-6))), $len], "str ok");
                    check_allocs(0, "allocs ok");
                };
                subtest 'has head space' => sub {
                    my $s = $class->$meth($exp);
                    get_allocs();
                    $s->offset($len - 3);
                    $s->insert(0, "world ");
                    cmp_deeply([$s->length, $s->data, $s->capacity], [9, string("world aaa"), 9], "str ok");
                    check_allocs(0, "allocs ok");
                };
                subtest 'has both space' => sub {
                    my $s = $class->$meth($exp);
                    get_allocs();
                    $s->offset(8, 5);
                    die "should not happen" if $s->capacity < 7;
                    $s->insert(0, "world ");
                    cmp_deeply([$s->length, $s->data, $s->capacity], [11, string("world aaaaa"), $len-2], "str ok");
                    check_allocs(0, "allocs ok");
                };
                subtest 'has summary space' => sub {
                    my $s = $class->$meth($exp);
                    get_allocs();
                    $s->offset(4, $len-8); # 4 free from head and tail
                    $s->insert(0, "world"); # 5 insterted
                    cmp_deeply([$s->length, $s->data, $s->capacity], [$len-3, string("world".("a" x ($len-8))), $len], "str ok"); # moved to the beginning
                    check_allocs(0, "allocs ok");
                };
                subtest 'has no space' => sub {
                    my $s = $class->$meth($exp);
                    get_allocs();
                    $s->offset(2, $len-4); # 2 free from head and tail
                    $s->insert(0, "world"); # 5 insterted
                    cmp_deeply([$s->length, $s->data, $s->capacity], [$len+1, string("world".("a" x ($len-4))), $len+1], "str ok"); # moved to the beginning
                    check_allocs([1,$buf_size+$len+1], ignore(), ignore(), ignore(), "allocs ok");
                };
            };
            subtest 'middle' => sub {
                subtest 'has end space' => sub {
                    my $s = $class->$meth($exp);
                    get_allocs();
                    $s->length($s->length - 6);
                    $s->insert(2, string("world "));
                    cmp_deeply([$s->length, $s->data, $s->capacity], [$len, string("aaworld ".("a"x($len-8))), $len], "str ok");
                    check_allocs(0, "allocs ok");
                };
                subtest 'has head space' => sub {
                    my $s = $class->$meth($exp);
                    get_allocs();
                    $s->offset($len - 3);
                    $s->insert(2, "world ");
                    cmp_deeply([$s->length, $s->data, $s->capacity], [9, string("aaworld a"), 9], "str ok");
                    check_allocs(0, "allocs ok");
                };
                subtest 'has both space' => sub {
                    my $s = $class->new_ptr($exp);
                    get_allocs();
                    $s->offset(8, 5);
                    die "should not happen" if $s->capacity < 7;
                    $s->insert(2, " world "); # head is shorter so, head is moved (7 bytes left)
                    cmp_deeply([$s->length, $s->data, $s->capacity], [12, "aa world aaa", $len-1], "str ok");
                    check_allocs(0, "allocs ok");
                    $s = $class->new_ptr($exp);
                    get_allocs();
                    $s->offset(8, 5);
                    $s->insert(3, " world "); # tail is shorter so tail is moved (7 bytes right)
                    cmp_deeply([$s->length, $s->data, $s->capacity], [12, "aaa world aa", $len-8], "str ok");
                    check_allocs(0, "allocs ok");
                };
                subtest 'has summary space' => sub {
                    my $s = $class->$meth($exp);
                    get_allocs();
                    $s->offset(4, $len-8); # 4 free from head and tail
                    $s->insert(2, "world"); # 5 insterted
                    cmp_deeply([$s->length, $s->data, $s->capacity], [$len-3, string("aaworld".("a" x ($len-10))), $len], "str ok"); # moved to the beginning
                    check_allocs(0, "allocs ok");
                };
                subtest 'has no space' => sub {
                    my $s = $class->$meth($exp);
                    get_allocs();
                    $s->offset(2, $len-4); # 2 free from head and tail
                    $s->insert(2, "world"); # 5 insterted
                    cmp_deeply([$s->length, $s->data, $s->capacity], [$len+1, string("aaworld".("a" x ($len-6))), $len+1], "str ok"); # moved to the beginning
                    check_allocs([1,$buf_size+$len+1], ignore(), ignore(), ignore(), "allocs ok");
                };
            };
        };
              
        subtest 'sso' => sub {
            return ok(1, "skipped for char size > 1") if $char_size > 1;
            $test->('new_ptr', $max_sso_chars);
        };
        get_allocs();
        subtest 'internal' => $test, 'new_ptr', 50;
        get_allocs();
        subtest 'external' => $test, 'new_external', 50;
        get_allocs();
        
        my $test_cow = sub {
            my $meth = shift;
            subtest 'end' => sub {
                my $s = $class->$meth("a" x 50);
                get_allocs();
                my $tmp = $class->new_copy($s);
                $s->length($s->length - 10);
                $s->insert($s->length, string("hello"));
                cmp_deeply([$s->length, $s->data, $s->capacity], [45, string(("a" x 40)."hello"), 45], "str ok");
                check_allocs([1,$buf_size+45],ignore(), "allocs ok");
            };
            get_allocs();
            subtest 'begin' => sub {
                my $s = $class->$meth("a" x 50);
                get_allocs();
                my $tmp = $class->new_copy($s);
                $s->offset(10, 30);
                $s->insert(0, string("hello"));
                cmp_deeply([$s->length, $s->data, $s->capacity], [35, string("hello".("a"x30)), 35], "str ok");
                check_allocs([1,$buf_size+35], "allocs ok");
            };
            get_allocs();
            subtest 'middle' => sub {
                my $s = $class->$meth("a" x 50);
                get_allocs();
                my $tmp = $class->new_copy($s);
                $s->offset(10, 30);
                $s->insert(5, string("hello"));
                cmp_deeply([$s->length, $s->data, $s->capacity], [35, string("aaaaahello".("a" x 25)), 35], "str ok");
                check_allocs([1,$buf_size+35], "allocs ok");
            };
            get_allocs();
        };
        
        subtest 'internal cow' => $test_cow, 'new_ptr';
        get_allocs();
        subtest 'external cow' => $test_cow, 'new_external';
        get_allocs();
    };
    
    subtest 'insert chars' => sub {
        my $s = $class->new_ptr(string("a" x 50));
        get_allocs();
        $s->insert_chars(20, 30, "b");
        cmp_deeply([$s->length, $s->data, $s->capacity], [80, string(("a" x 20).("b" x 30).("a" x 30)), 80], "str ok");
        check_allocs([1,$buf_size+80],ignore(), "allocs ok");
    };
    get_allocs();
    
    subtest 'replace shrink' => sub {
        subtest 'literal' => sub {
            my $s = $class->new_literal;
            my $tmp = $literal_src;
            substr($tmp, 5, 5, "hi");
            $tmp = string($tmp);
            $s->replace(5, 5, string("hi"));
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($tmp), $tmp, str_len($tmp)], "str ok");
            check_allocs([1,$buf_size+str_len($tmp)], "allocs ok");
        };
        
        my $test = sub {
            my $meth = shift;
            my $len  = shift;
            my $s = $class->$meth("a" x $len);
            get_allocs();
            $s->replace(5, 10, string("hello"));
            cmp_deeply([$s->length, $s->data, $s->capacity], [$len-5, string(("a"x5)."hello".("a"x($len-15))), $len], "str ok");
            check_allocs(0, "allocs ok");
            $s->replace(0, 5, "");
            cmp_deeply([$s->length, $s->data, $s->capacity], [$len-10, string("hello".("a"x($len-15))), $len-5], "str ok");
            check_allocs(0, "allocs ok");
        };
        subtest 'sso' => sub {
            return ok(1, "skipped for char size > 1") if $char_size > 1;
            $test->('new_ptr', $max_sso_chars);
        };
        get_allocs();
        subtest 'internal' => $test, 'new_ptr', 50;
        get_allocs();
        subtest 'external' => $test, 'new_external', 50;
        get_allocs();
    };
    
    subtest 'replace grow' => sub {
        subtest 'literal' => sub {
            my $exp = string("epta");
            my $s = $class->new_literal;
            $s->replace(5, 10, $exp);
            my $tmp = $literal_src;
            substr($tmp, 5, 10, "epta");
            $tmp = string($tmp);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($tmp), $tmp, str_len($tmp)], "str ok");
            check_allocs([1,$buf_size+str_len($tmp)], "allocs ok");
        };
        
        my $test = sub {
            my $meth = shift;
            my $len  = shift;
            my $exp  = string("a" x $len);
            
            subtest 'has end space' => sub {
                my $s = $class->$meth($exp);
                get_allocs();
                $s->length($s->length - 3);
                $s->replace(3, 3, string("world "));
                cmp_deeply([$s->length, $s->data, $s->capacity], [$len, string("aaaworld ".("a"x($len-9))), $len], "str ok");
                check_allocs(0, "allocs ok");
            };
            get_allocs();
            subtest 'has head space' => sub {
                my $s = $class->$meth($exp);
                get_allocs();
                $s->offset($len - 10);
                $s->replace(2, 2, "world ");
                cmp_deeply([$s->length, $s->data, $s->capacity], [14, string("aaworld aaaaaa"), 14], "str ok");
                check_allocs(0, "allocs ok");
            };
            get_allocs();
            subtest 'has both space' => sub {
                my $s = $class->new_ptr($exp);
                get_allocs();
                $s->offset(8, 5);
                die "should not happen" if $s->capacity < 7;
                $s->replace(1,2, " world "); # head is shorter so, head is moved (5 bytes to left)
                cmp_deeply([$s->length, $s->data, $s->capacity], [10, "a world aa", $len-3], "str ok");
                check_allocs(0, "allocs ok");
                $s = $class->new_ptr($exp);
                get_allocs();
                $s->offset(8, 5);
                $s->replace(2,2, " world "); # tail is shorter so tail is moved (5 bytes to right)
                cmp_deeply([$s->length, $s->data, $s->capacity], [10, "aa world a", $len-8], "str ok");
                check_allocs(0, "allocs ok");
            };
            get_allocs();
            subtest 'has summary space' => sub {
                my $s = $class->$meth($exp);
                get_allocs();
                $s->offset(4, $len-8); # 4 free from head and tail
                $s->replace(4,6, "hello world"); # 5 inserted
                cmp_deeply([$s->length, $s->data, $s->capacity], [$len-3, string("aaaahello world".("a" x ($len-18))), $len], "str ok"); # moved to the beginning
                check_allocs(0, "allocs ok");
            };
            get_allocs();
            subtest 'has no space' => sub {
                my $s = $class->$meth($exp);
                get_allocs();
                $s->offset(2, $len-4); # 2 free from head and tail
                $s->replace(4,6, "hello world"); # 5 insterted
                cmp_deeply([$s->length, $s->data, $s->capacity], [$len+1, string("aaaahello world".("a" x ($len-14))), $len+1], "str ok"); # moved to the beginning
                check_allocs([1,$buf_size+$len+1], ignore(), ignore(), ignore(), "allocs ok");
            };
            get_allocs();
        };
        
        subtest 'sso' => sub {
            return ok(1, "skipped for char size > 1") if $char_size > 1;
            $test->('new_ptr', $max_sso_chars);
        };
        subtest 'internal' => $test, 'new_ptr', 50;
        subtest 'external' => $test, 'new_external', 50;
    };

    subtest 'replace chars' => sub {
        my $s = $class->new_ptr(string("a" x 50));
        get_allocs();
        $s->replace_chars(20, 10, 30, "b");
        cmp_deeply([$s->length, $s->data, $s->capacity], [70, string(("a" x 20).("b" x 30).("a" x 20)), 70], "str ok");
        check_allocs([1,$buf_size+70],ignore(), "allocs ok");
    };
    get_allocs();
    
    subtest 'shared detach' => sub {
        subtest 'literal' => sub {
            my $s = $class->new_literal;
            $s->shared_detach();
            is($s->capacity, str_len($literal_str), "detached");
            check_allocs([1,$buf_size+str_len($literal_str)], "allocs ok");
        };
        get_allocs();
        subtest 'sso' => sub {
            my $s = $class->new_ptr(string("ab"));
            $s->shared_detach;
            is($s->capacity, $max_sso_chars, "noop");
            check_allocs(0, "allocs ok");
        };
        subtest 'internal' => sub {
            my $s = $class->new_ptr(string("a" x 50));
            $s->offset(0, 10);
            get_allocs();
            $s->shared_detach;
            is($s->capacity, 50, "noop");
            check_allocs(0, "allocs ok");
            my $tmp = $class->new_copy($s);
            $s->shared_detach;
            is($s->shared_capacity, 50, "noop");
            check_allocs(0, "allocs ok");
        };
        get_allocs();
        subtest 'external' => sub {
            my $s = $class->new_external(string("a" x 50));
            $s->offset(0, 10);
            get_allocs();
            $s->shared_detach;
            is($s->capacity, 50, "noop");
            check_allocs(0, "allocs ok");
            my $tmp = $class->new_copy($s);
            $s->shared_detach;
            is($s->shared_capacity, 50, "noop");
            check_allocs(0, "allocs ok");
        };
        get_allocs();
    };
    
    if ($class->can("to_number")) {
        subtest 'to number' => sub {
            my $s = $class->new_ptr("  1020asd");
            is($s->to_number, 1020);
            is($s->to_number(3), 20);
            is($s->to_number(4,1), 2);
            is($s->to_number(0, 999, 16), 66058);
            is($s->to_number(2, 9, 2), 2);
            is($s->to_number(5), 0);
            is($s->to_number(6), undef);
        };
    }
    
    if ($class->can("from_number")) {
        subtest 'from number' => sub {
            my $s;
            $s = $class->from_number(10);
            cmp_deeply([$s->length, $s->data], [2, "10"]);
            $s = $class->from_number(10, 8);
            cmp_deeply([$s->length, $s->data], [2, "12"]);
            $s = $class->from_number(10, 16);
            cmp_deeply([$s->length, $s->data], [1, "a"]);
        };
    }
    
    subtest 'from alien allocator' => sub {
        subtest 'from literal' => sub {
            my $src = $other_alloc_class->new_literal;
            my $s = $class->new_copy_other($src);
            cmp_deeply([$s->length, $s->data, $s->capacity], [str_len($literal_str), $literal_str, 0], "str ok");
            undef $s; undef $src;
            check_allocs(0, "no allocs");
            check_other_allocs(0, "no other allocs");
        };
        subtest 'from sso' => sub {
            my $exp = string("ab");
            my $src = $other_alloc_class->new_ptr($exp);
            my $s = $class->new_copy_other($src);
            cmp_deeply([$s->length, $s->data, $s->capacity], [2, $exp, $max_sso_chars], "str ok");
            undef $s; undef $src;
            check_allocs(0, "no allocs");
            check_other_allocs(0, "no other allocs");
        };
        subtest 'from internal' => sub {
            my $exp = string("a" x 50);
            my $src = $other_alloc_class->new_ptr($exp);
            check_other_allocs([1,$buf_size+50], "other allocated");
            my $s = $class->new_copy_other($src);
            check_other_allocs(0, "no other allocs yet");
            cmp_deeply([$s->length, $s->data, $s->caps], [50, $exp, 0,50], "str ok");
            undef $src;
            check_other_allocs(0, "no other allocs yet");
            undef $s;
            check_other_allocs(0,[1,$buf_size+50], "other deallocated");
            check_allocs(0, "no native allocs");
        };
        subtest 'from external' => sub {
            my $exp = string("b" x 50);
            my $src = $other_alloc_class->new_external($exp);
            check_other_allocs([1,$ebuf_size], "other allocated");
            my $s = $class->new_copy_other($src);
            check_other_allocs(0, "no other allocs yet");
            cmp_deeply([$s->length, $s->data, $s->caps], [50, $exp, 0,50], "str ok");
            undef $src;
            check_other_allocs(0, "no other allocs yet");
            undef $s;
            check_other_allocs(0,[1,$ebuf_size],0,[1,50], "other deallocated");
            check_allocs(0, "no native allocs");
        };
        subtest 'from external with custom buf' => sub {
            my $exp = string("b" x 50);
            my $src = $other_alloc_class->new_external_custom_buf($exp);
            check_other_allocs(0, "other no allocs");
            my $s = $class->new_copy_other($src);
            check_other_allocs(0, "no other allocs yet");
            cmp_deeply([$s->length, $s->data, $s->caps], [50, $exp, 0,50], "str ok");
            undef $src;
            check_other_allocs(0, "no other allocs yet");
            undef $s;
            check_other_allocs(0,0,0,[1,50],1, "other deallocated with custom buf");
            check_allocs(0, "no native allocs");
        };
    };
}

sub immortal {
    my $str = shift;
    push @immortal, $str;
    return $str;
}

sub str_len {
    return length($_[0]) / $char_size;
}

sub string {
    my $char_str = shift;
    return $char_str if $char_size == 1;
    die "not impl";
}

# check_allocs flushes allocations counters because get_allocs() does
sub check_allocs       { return _check_allocs(@_, 0) }
sub check_other_allocs { return _check_allocs(@_, 1) }
sub _check_allocs      {
    my $n = pop;
    my $name = pop;
    my ($allocated, $deallocated, $reallocated, $ext_deallocated, $ext_shbuf_deallocated) = @_;
    foreach my $item ($allocated, $deallocated, $reallocated, $ext_deallocated) {
        $item = [ignore(), ignore()] if ref($item) eq ref(ignore());
        $item //= [0,0];
        $item = [$item, $item] unless ref $item;
    }
    $ext_shbuf_deallocated //= 0;
    cmp_deeply(get_allocs($n), {
        allocated_cnt         => $allocated->[0],
        allocated             => $allocated->[1],
        deallocated_cnt       => $deallocated->[0],
        deallocated           => $deallocated->[1],
        reallocated_cnt       => $reallocated->[0],
        reallocated           => $reallocated->[1],
        ext_deallocated_cnt   => $ext_deallocated->[0],
        ext_deallocated       => $ext_deallocated->[1],
        ext_shbuf_deallocated => $ext_shbuf_deallocated,
    }, $name);
}

sub get_other_allocs { get_allocs(1) }
