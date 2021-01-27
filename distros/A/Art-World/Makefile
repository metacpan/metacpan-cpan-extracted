CARTONEX=carton exec

dependencies-install:
	carton install

build:
	perl Build.PL
	./Build
	./Build test
	./Build install

test-v:
	${CARTONEXE} -- prove -vl t/

test:
	${CARTONEXE} -- prove -l t/

test-agent:
	${CARTONEXE} -- prove -vl t/03_agent.t

test-manager:
	${CARTONEXE} -- prove -vl t/07_manager.t

test-entities:
	${CARTONEXE} -- prove -vl t/02_abstraction.t

test-db:
	${CARTONEXE} -- prove -vl t/20_db.t

test-introspection:
	 ${CARTONEXE} -- prove -vl t/30_introspection.t
