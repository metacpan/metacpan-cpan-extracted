# share_skill details

Detail for `dbio-perl-release` § *Agent skills (share_skill)*.

- The EV dists (`dbio-postgresql-ev`, `dbio-mysql-ev`) use `[@Filter] -bundle = @DBIO`
  (with `-remove = MakeMaker` and their own `[MakeMaker]`); `dbio-async`, `dbio-forked`
  and the extensions use plain `[@DBIO]`. In a `[@Filter]` dist put `share_skill` inside
  the `[@Filter]` section. It reaches the bundle as a plain scalar (Filter does not
  know it is multivalue) — the `share_skill` attr accepts scalar or arrayref.
- Runtime (in `DBIO` core): `DBIO::Skills` exposes the installed sharedir skills;
  `DBIO->skill($name)` / `$schema->skill($name)` retrieve them. A schema may
  override via its `skills` classdata — sugar `skills({...})` / `skill(k => v)`
  under `use DBIO 'Schema', -<driver>`, or `->connect(..., { skills => {...} })`.
  `bin/dbio-skills -MMyApp::Schema --deploy` deploys them into `.claude/skills/`.
