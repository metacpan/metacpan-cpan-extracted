# One line per atom of model 1, as gemmi reads it.
#
# Written for t/oracle.t and t/data/oracle.pl, which are the only two things
# that run it: the test compares this module against gemmi live where gemmi is
# installed, and the generator freezes this output into oracle.txt so that the
# comparison still runs where it is not.  One copy of the script, so the frozen
# answer and the live one cannot be answers to different questions.
#
# Usage: python3 oracle.py FILE
#
# The rows are sorted, so the comparison does not depend on either reader's
# idea of the order.  The residue name is the last field, on its own, because a
# residue modelled in two chemical states at once is one residue to this module
# and two to gemmi -- see the head of t/oracle.t.
#
# gemmi 0.7.5, importable from /home/con/.pyenv/versions/3.14.2/bin/python3.
import sys
import gemmi

st = gemmi.read_structure(sys.argv[1])
rows = []
if len(st):
    for chain in st[0]:
        for res in chain:
            for at in res:
                alt = '' if at.altloc in ('', '\x00') else at.altloc
                rows.append('%s|%d|%s|%s|%s|%.3f|%.3f|%.3f|%s' % (
                    chain.name, res.seqid.num, res.seqid.icode.strip(),
                    at.name, alt, at.pos.x, at.pos.y, at.pos.z, res.name))
print('\n'.join(sorted(rows)))
# rstrip so that a field the file does not answer prints as a bare '#field'
# rather than as a line with trailing whitespace: the frozen copy in oracle.txt
# is committed, and trailing whitespace in a committed file does not survive
# every editor.
print('#models %d' % len(st))
print(('#resolution %s' % (st.resolution or '')).rstrip())
print(('#spacegroup %s' % (st.spacegroup_hm or '')).rstrip())
