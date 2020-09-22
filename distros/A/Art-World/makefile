dependencies-install:
	carton install

build:
	perl Build.PL
	./Build
	./Build test
	./Build install

test-v:
	carton exec -- prove -vl

test:
	carton exec -- prove -l

test-entities:
	carton exec -- prove -vl t/02-entities.t

test-db:
	prove -ve 'perl6 -Ilib' t/03-db.t

test-introspection:
	prove -ve 'perl6 -Ilib' t/04-introspection.t

test-liz-trait:
	prove -ve 'perl6 -Ilib' t/05-liz-crud-spec.t

test-agent:
	prove -ve 'perl6 -Ilib' t/06-agent.t
