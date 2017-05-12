-- Deploy robobot:p-skills-20161128231536 to pg
-- requires: p-skills-20161128215019

BEGIN;

INSERT INTO robobot.skills_levels (name, sort_order, description) VALUES
    ('Plebe',        -1, 'Heard of the topic, but know next to nothing about it. (But do want to be pinged when others are talking about it.)'),
    ('Novice',        0, 'Tinkered a bit with something, but still very green.'),
    ('Intermediate',  1, 'Reasonable, but certainly not extensive knowledge about the topic.'),
    ('Advanced',      2, 'Solid knowledge and significant experience with the topic.'),
    ('Expert',        3, 'You know a lot of the tricks, have probably contributed libraries/patches/features, and may even be active on mailing lists and IRC channels.'),
    ('Creator',       4, 'Actually the honest-to-goodness (co-)creator of the project, language, tool, etc. If you don''t know the answer, hope is probably lost.'),
    ('Thoughtlord',  10, 'You are Jon Hendren. http://www.jonhendren.com/');

COMMIT;
