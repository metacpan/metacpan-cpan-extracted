# storage->deploy nativ — entschieden in Core-ADR 0064

Die Entscheidung steht im Core: ADR 0064,
`dbio/docs/adr/0064-storage-deploy-installs-through-the-native-deploy-class.md`
(karr dbio k337).

- `DBIO::Storage::DBI::deploy` installiert über die Klasse, die
  `dbio_deploy_class` des Storage nennt; eine DDL-Datei im Deploy-Verzeichnis
  wird nicht an ihrer Stelle ausgeführt.
- `deployment_statements` ist der Leser einer DDL-Datei — für jeden Treiber,
  mit und ohne Deploy-Klasse.

Was dieses Repo daraus umsetzt (karr k104):

- `DBIO::PostgreSQL::Storage` hat kein eigenes `deploy` und kein eigenes
  `deployment_statements`; beide sind die des Core. `$storage->deploy($schema)`
  und `$schema->deploy` enden im selben Install, mit und ohne die
  `DBIO::PostgreSQL`-Komponente.
- `dbio_deploy_class` am Storage ist die eine Stelle, die die Deploy-Klasse
  nennt. `$schema->pg_deploy` fragt dort, also auch die Storage-Schicht einer
  Erweiterung, die eine eigene Deploy-Klasse nennt.
- Install-DDL liefern `$schema->pg_install_ddl` und
  `DBIO::PostgreSQL::DDL->install_ddl`.
- Gehalten von `t/107-deployment-statements-no-server.t`,
  `t/128-storage-deploy-class.t` und `t/128-storage-deploy-class-live.t`.
