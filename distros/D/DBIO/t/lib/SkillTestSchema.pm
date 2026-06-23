package # hide from PAUSE
    SkillTestSchema;

# Exercises the DBIO 'Schema' pragma's skills-override declaration sugar.
use DBIO 'Schema';

skills({ 'core' => "CLASS-CORE\n" });   # set/replace the whole override map
skill('mysql-database' => "CLASS-MYSQL\n"); # merge a single entry

1;
