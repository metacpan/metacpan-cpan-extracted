      module radec2rad_mod

      contains

      subroutine radec2rad(ra1,ra2,ra3,dec1,dec2,dec3,  &
           alpha,delta)
!
      implicit none

      integer, intent(in) :: ra1, ra2, dec1, dec2
      real, intent(out) :: alpha, delta
      real, intent(in) :: ra3, dec3
      real twopi,dsign
!
      twopi=8.0*atan(1.0)
!
      alpha=twopi*(ra1+ra2/60.0+ra3/3600.0)/24.00
      if(dec1 > 0.0)dsign=1.0
      if (dec1.lt.0.0)dsign=-1.0
      if (dec1.eq.-0.0)dsign=-1.0
      if (dec2.lt.0.0)dsign=-1.0
      if (dec3.lt.0.0)dsign=-1.0
!      dec1=abs(dec1)
!      dec2=abs(dec2)
!      dec3=abs(dec3)
      delta=dsign*twopi*(abs(dec1)+abs(dec2)/60.0+abs(dec3)/3600.0)/360.0
 19   return
      end subroutine radec2rad

      end module radec2rad_mod



