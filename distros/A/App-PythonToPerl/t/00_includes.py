# DEV NOTE, CORRELATION PYIN000: any changes to test includes below must also be made in lib/Python/Include.pm

# regex #0
import FOO
import F.OO
import F.OO# test comment
import F.OO  # test comment
import \
    FOO

# regex #1
import FOO, BAR, BAT, BAX
import F.OO , B.AR, BA.T, B.A.X
import F.OO,B.AR,BA.T,B.A.X# test comment
import F.OO, B.AR, BA.T, B.A.X  # test comment
import \
    FOO, B.AR, \
    BA.T, B.A.X  # test comment

# regex #2
from FOO import BAR
from F.OO import B.AR
from F.OO import B.AR# test comment
from F.OO import B.AR  # test comment
from \
    F.OO \
    import \
    B.AR  # test comment
from . import BAR
from . import B.AR
from . import B.AR# test comment
from . import B.AR  # test comment
from \
    . \
    import \
    B.AR  # test comment

# regex #3
from FOO import BAR, BAT, BAX
from F.OO import B.AR , BA.T, B.A.X
from F.OO import B.AR,BA.T,B.A.X# test comment
from F.OO import B.AR, BA.T, B.A.X  # test comment
from \
    F.OO \
    import B.AR, \
    BA.T, B.A.X  # test comment
from FOO import \
    BAR, \
    BAT, \
    BAX
from FOO import FU, FEW, \
    BAR, BHAR \
    ,BAT, \
    BAX, BHAX
from F.OO import F.U, F.E.W, \
    B.AR, BH.AR, \
    BA.T, \
    B.A.X, B.H.A.X  # test comment

# regex #4
from FOO import ( BAR, BAT, BAX )
from FOO import ( B.AR , BA.T, B.A.X, )
from FOO import(B.AR,BA.T,B.A.X)#test comment
from FOO import ( B.AR, BA.T, B.A.X )  # test comment
from FOO import (
    BAR,
    BAT,
    BAX
)
from FOO import ( FU, FEW,
    BAR, BHAR,
    BAT,
    BAX, BHAX,
)
from F.OO import ( F.U, F.E.W,
    B.AR, BH.AR,
    BA.T,
    B.A.X, B.H.A.X
)
from FOO import ( \
    BAR, \
    BAT,# test comment
    BAX \
)# test comment
from FOO import ( FU, FEW, \
    BAR, BHAR, \
    BAT,
    BAX, BHAX \
)
from \
    F.OO \
    import \
    ( \
    F.U, F.E.W, \
    B.AR, BH.AR, \
    BA.T, \
    B.A.X, B.H.A.X \
)

# regex #5
import FOO as F
import F.OO as F
import F.OO as F# test comment
import F.OO as F  # test comment
import \
    F.OO \
    as \
    F  # test comment

# regex #6
from FOO import BAR as B
from F.OO import B.AR as B
from F.OO import B.AR as B# test comment
from F.OO import B.AR as B  # test comment
from \
    F.OO \
    import \
    B.AR \
    as \
    B  # test comment
