  module cluster_match_subs

    use define_star

    implicit none

    contains

    subroutine read_cluster_file(iunit, nstars, ncol, colstr, star) 

      ! Reads in a cluster format file on an already open unit.

      integer, intent(in) :: iunit
      integer, intent(out) :: nstars, ncol
      character(len=*), dimension(:), intent(out) :: colstr
      type(a_star), dimension(:), allocatable, intent(out) :: star

      integer :: iostat, i, istar
      character(len=30) :: tmpstr

      ! Three lines of header.
      read(iunit,'(/,/)')
      nstars=0.0
      count_them: do
        read(iunit,*, iostat=iostat) i
        if (iostat < 0) exit count_them
        nstars=nstars+1
      end do count_them
      rewind(iunit)
      read(iunit,*,iostat=iostat) ncol
      if (iostat < 0) ncol=4
      ! The next line should have the names of the colours on it, but
      ! it may not.
      read(iunit,'(a30)') tmpstr
      read(tmpstr,*,iostat=iostat) (colstr(i),i=1,ncol)
      if (iostat < 0) colstr=' '
      read(iunit,*)
      allocate(star(nstars))
      do istar=1, nstars
        iostat=read_star(iunit, star(istar), ncol)
        if (iostat /= 0) then
          print*, 'Error reading that file, iostat is', iostat
          print*, 'For line number ', istar+3
        end if
      end do

    end subroutine read_cluster_file


    subroutine match_them(nstars1, star1, alpha, delta, another_star, &
    fixrad, matches, n_matches)

      ! Originally the program cluster_match, but made into a subroutine
      ! so it could be used for the e-star project.

      use radec2rad_mod

      implicit none

      ! The primary catalogue, its RAs and decs in radians, and the number of
      ! stars. 
      integer, intent(in) :: nstars1
      type(a_star), dimension(nstars1), intent(in) :: star1
      real, dimension(:), intent(in) :: alpha, delta

      ! A star for which you want to find the matches.
      type(a_star), intent(in) :: another_star

      ! The matching radius (<0 if provided in another_star).
      real, intent(in) :: fixrad

      ! The array element numbers from star1, which are possible counterparts
      ! to star2, and the number of possible matches.
      integer, dimension(nstars1), intent(out) :: matches
      integer, intent(out) :: n_matches

      ! Locals.
      integer :: i, ibright
      real :: rad, dist, bright
      real :: another_delta, another_alpha

      call radec2rad(another_star%ra_h, another_star%ra_m, &
      another_star%ra_s, another_star%dc_d, another_star%dc_m, &
      another_star%dc_s, another_alpha, another_delta)
      if (fixrad > 0) then
        rad=fixrad
      else
        rad=another_star%col(1)%data
      end if
      rad=rad/206264.8
      n_matches=0
      do i=1, nstars1
        if (abs(another_delta-delta(i)) < rad) then
          dist=(another_alpha-alpha(i))
          dist=dist*cos((another_delta+delta(i))/2.0)
          dist=dist**2.0
          dist=dist+(another_delta-delta(i))**2.0
          if (dist < rad*rad) then
            n_matches=n_matches+1
            matches(n_matches)=i
          end if
        end if
      end do

      if (n_matches > 1) then
        ! Ensure the first match is the brightest.
        ibright=0
        bright=huge(star1(matches(1))%col(1)%data)
        do i=1, n_matches
          if (star1(matches(i))%col(1)%flg == 0) then
            if (star1(matches(i))%col(1)%data < bright) then
              ibright=i
              bright=star1(matches(i))%col(1)%data
            end if
          end if
        end do
        if (ibright /= 0) then
          i=matches(ibright)
          matches(ibright)=matches(1)
          matches(1)=i
        end if
      end if

    end subroutine match_them

  end module cluster_match_subs
