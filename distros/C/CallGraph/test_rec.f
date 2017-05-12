
      PROGRAM MAIN
      CALL EXTSUB(X)
      CALL SUB1(X)
      CALL SUB2(X)
      END
      
      SUBROUTINE SUB1(X)
      CALL SUB11(X)
      CALL SUB12(X)
      END
      
      SUBROUTINE SUB2(X)
      CALL SUB12(X)
      CALL SUB21(X)
      END

      SUBROUTINE SUB11(X)
      END

      SUBROUTINE SUB12(X)
      CALL SUB1
      END
      
      SUBROUTINE SUB21(X)
      END
      
