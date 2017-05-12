  module define_star

    implicit none

    integer, parameter :: mcol=4

    type a_colour
      real :: data
      real :: err
      integer :: flg
    end type a_colour
  
    type a_star
      integer :: field, id
      integer :: ra_h, ra_m
      real :: ra_s
      integer :: dc_d, dc_m
      real :: dc_s
      real :: x, y
      type(a_colour), dimension(mcol) :: col
    end type a_star

    contains

    subroutine write_star(iunit, star, ncol)

      integer, intent(in) :: iunit
      type(a_star), intent(in) :: star
      integer, optional :: ncol

      integer :: icol, jcol
      real xpos, ypos
      
      jcol=mcol
      if (present(ncol)) jcol=ncol

      xpos=star%x
      ypos=star%y
      if (xpos<-999.99 .or. xpos>9999.99 &
     .or. ypos<-999.99 .or. ypos>9999.99) then
        xpos=0.0
        ypos=0.0
      end if

      write(iunit,10) star%field, star%id, star%ra_h, &
      star%ra_m, star%ra_s, star%dc_d, star%dc_m, star%dc_s, xpos, &
      ypos, (star%col(icol),icol=1,jcol)
      
10    format(1x,i3,2x,i5,2x,2(i3.2,1x,i2.2,1x,f5.2,2x),2(f8.3,2x),&
      4(f9.3,2x,f9.3,2x,i3.2))
      
    end subroutine write_star

    integer function read_star(iunit, star, ncol)

      integer, intent(in) :: iunit
      type(a_star), intent(inout) :: star
      integer, optional :: ncol

      integer :: icol, jcol, iostat

      jcol=mcol
      if (present(ncol)) jcol=ncol

      read(iunit,*, iostat=iostat) star%field, star%id, star%ra_h, &
      star%ra_m, star%ra_s, star%dc_d, star%dc_m, star%dc_s, star%x, &
      star%y, (star%col(icol),icol=1,jcol)

      if (jcol < mcol) then
        do icol=jcol+1, mcol
          star%col(icol)%data=0.0
          star%col(icol)%err=0.0
          star%col(icol)%flg=77
        end do
      end if

      read_star=iostat

    end function read_star

    subroutine zero_star(star)

      type(a_star), intent(inout), dimension(:) :: star

      integer :: icol

      star%field=0
      star%id=0
      star%ra_h=0
      star%ra_m=0
      star%ra_s=0.0
      star%dc_d=0
      star%dc_m=0
      star%dc_s=0.0
      star%x=0.0
      star%y=0.0
      do icol=1, mcol
        star%col(icol)%data=0.0
        star%col(icol)%err=0.0
        star%col(icol)%flg=0
      end do
    
    end subroutine zero_star

  end module define_star
