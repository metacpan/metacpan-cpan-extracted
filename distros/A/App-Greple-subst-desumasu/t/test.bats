#!/usr/bin/env bats

@test "Jotai" {
	[ "$(perl -Ilib -S greple -Msubst::desumasu --dearu --subst --all --no-color t/t1-s.txt)" = "$(cat t/t2-s.txt)" ]
#	[ "$(cat test/t1-s.txt|dist/cli.js -j|tr \"\\n\" 'X' )" = "$(cat test/t2-s.txt|tr \"\\n\" 'X' )" ]
}

@test "Keitai" {
	[ "$(perl -Ilib -S greple -Msubst::desumasu --desumasu --subst --all --no-color t/t2-s.txt)" = "$(cat t/t2-r.txt)" ]
#	[ "$(cat t/t2-s.txt|tr \"\\n\" 'X' )" = "$(cat t/t2-r.txt|tr \"\\n\" 'X' )" ]
}

@test "Jotai-n" {
	[ "$(perl -Ilib -S greple -Msubst::desumasu --dearu-n --subst --all --no-color t/t1-s.txt)" = "$(cat t/t3-r.txt)" ]
#	[ "$(cat t/t1-s.txt|tr \"\\n\" 'X' )" = "$(cat t/t3-r.txt|tr \"\\n\" 'X' )" ]
}

@test "Jotai-N" {
	[ "$(perl -Ilib -S greple -Msubst::desumasu --dearu-N --subst --all --no-color t/t1-s.txt)" = "$(cat t/t4-r.txt)" ]
#	[ "$(cat t/t1-s.txt|tr \"\\n\" 'X' )" = "$(cat t/t4-r.txt|tr \"\\n\" 'X' )" ]
}

